import importlib.util
import re
import subprocess
import sys
import tempfile
import uuid
from dataclasses import dataclass
from pathlib import Path
from types import ModuleType

from mojo.paths import MojoCompilationError
from mojo.run import subprocess_run_mojo


GRAPH_IMPORT_PLACEHOLDER = "# __GRAPH_IMPORT__"
MMM_AUDIO_SHIM = "from mmmaudio import *\n"
MODULE_NAME_RE = re.compile(r"[^A-Za-z0-9_]")
RUNTIME_IMPORTS = {"from mmm_audio import *", "from mmmaudio import *"}
FROM_IMPORT_RE = re.compile(r"^\s*from\s+([A-Za-z0-9_\.]+)\s+import\s+(.+?)\s*$")
IMPORT_RE = re.compile(r"^\s*import\s+([A-Za-z0-9_\.]+)(?:\s+as\s+([A-Za-z0-9_]+))?\s*$")


@dataclass
class LoadedGraphBridge:
    build_dir: tempfile.TemporaryDirectory[str]
    module: ModuleType
    module_name: str
    shared_library_path: Path


def _sanitize_identifier(value: str) -> str:
    sanitized = MODULE_NAME_RE.sub("_", value)
    if not sanitized:
        sanitized = "graph"
    if sanitized[0].isdigit():
        sanitized = f"g_{sanitized}"
    return sanitized


def _resolve_local_module(module_name: str, current_dir: Path, source_root: Path) -> Path | None:
    normalized = module_name.lstrip(".")
    if not normalized:
        return None

    relative_path = Path(*normalized.split("."))
    if module_name.startswith("."):
        search_roots = [current_dir]
    else:
        search_roots = [current_dir, source_root]

    checked: set[Path] = set()
    for root in search_roots:
        for candidate in (root / f"{relative_path}.mojo", root / relative_path / "__init__.mojo"):
            resolved = candidate.resolve()
            if resolved in checked:
                continue
            checked.add(resolved)
            if candidate.exists():
                return resolved
    return None


def _discover_dependency_files(graph_source: Path, source_root: Path) -> set[Path]:
    dependency_files: set[Path] = set()
    pending = [graph_source.resolve()]

    while pending:
        current = pending.pop()
        if current in dependency_files:
            continue
        dependency_files.add(current)

        for raw_line in current.read_text(encoding="utf-8").splitlines():
            stripped = raw_line.strip()
            if not stripped or stripped.startswith("#") or stripped in RUNTIME_IMPORTS:
                continue

            module_name = None
            from_match = FROM_IMPORT_RE.match(raw_line)
            if from_match:
                module_name = from_match.group(1)
            else:
                import_match = IMPORT_RE.match(raw_line)
                if import_match:
                    module_name = import_match.group(1)

            if module_name is None:
                continue

            local_module = _resolve_local_module(module_name, current.parent, source_root)
            if local_module is not None and local_module not in dependency_files:
                pending.append(local_module)

    return dependency_files


def _module_path_for_file(file_path: Path, source_root: Path) -> str:
    relative_path = file_path.relative_to(source_root)
    if relative_path.name == "__init__.mojo":
        parts = relative_path.parent.parts
    else:
        parts = relative_path.with_suffix("").parts
    if not parts:
        raise ValueError(f"Cannot derive module path for {file_path}")
    return ".".join(parts)


def _normalize_graph_source(source: Path, source_root: Path) -> str:
    normalized_lines: list[str] = []

    for raw_line in source.read_text(encoding="utf-8").splitlines():
        stripped = raw_line.strip()
        if stripped in RUNTIME_IMPORTS:
            normalized_lines.append("from mmm_audio import *")
            continue

        from_match = FROM_IMPORT_RE.match(raw_line)
        if from_match:
            module_name, imported_names = from_match.groups()
            local_module = _resolve_local_module(module_name, source.parent, source_root)
            if local_module is not None:
                normalized_lines.append(
                    f"from {_module_path_for_file(local_module, source_root)} import {imported_names}"
                )
                continue

        import_match = IMPORT_RE.match(raw_line)
        if import_match:
            module_name, alias = import_match.groups()
            local_module = _resolve_local_module(module_name, source.parent, source_root)
            if local_module is not None:
                rewritten = f"import {_module_path_for_file(local_module, source_root)}"
                if alias is not None:
                    rewritten += f" as {alias}"
                normalized_lines.append(rewritten)
                continue

        normalized_lines.append(raw_line)

    return "\n".join(normalized_lines) + "\n"


def _ensure_package_inits(directory: Path, build_root: Path) -> None:
    current = directory
    while current != build_root:
        init_path = current / "__init__.mojo"
        if not init_path.exists():
            init_path.write_text("", encoding="utf-8")
        current = current.parent


def _stage_dependency_graph(graph_source: Path, source_root: Path, build_root: Path) -> None:
    for dependency in _discover_dependency_files(graph_source, source_root):
        relative_path = dependency.relative_to(source_root)
        destination = build_root / relative_path
        destination.parent.mkdir(parents=True, exist_ok=True)
        _ensure_package_inits(destination.parent, build_root)
        destination.write_text(_normalize_graph_source(dependency, source_root), encoding="utf-8")


def _build_graph_import(graph_source: Path, source_root: Path, graph_name: str) -> str:
    return f"from {_module_path_for_file(graph_source, source_root)} import {graph_name}"


def _build_bridge_source(template_path: Path, graph_import: str, graph_name: str, module_name: str) -> str:
    source = template_path.read_text(encoding="utf-8")
    source = source.replace(GRAPH_IMPORT_PLACEHOLDER, graph_import)
    source = source.replace("FeedbackDelays", graph_name)
    source = source.replace('PythonModuleBuilder("MMMAudioBridge")', f'PythonModuleBuilder("{module_name}")')
    source = source.replace("PyInit_MMMAudioBridge", f"PyInit_{module_name}")
    return source


def _compile_bridge_module(bridge_source_path: Path, output_so_path: Path, build_root: Path, project_root_parent: Path) -> None:
    mojo_args = [
        "build",
        str(bridge_source_path),
        "--emit",
        "shared-lib",
        "-o",
        str(output_so_path),
        "-I",
        str(build_root),
        "-I",
        str(project_root_parent),
    ]

    try:
        subprocess_run_mojo(
            mojo_args,
            cwd=str(build_root),
            capture_output=True,
            check=True,
        )
    except subprocess.CalledProcessError as exc:
        raise MojoCompilationError.from_subprocess_error(bridge_source_path, mojo_args, exc) from exc


def _load_extension_module(module_name: str, shared_library_path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(module_name, shared_library_path)
    if spec is None or spec.loader is None:
        raise ImportError(f"Unable to create import spec for {shared_library_path}")

    module = importlib.util.module_from_spec(spec)
    sys.modules[module_name] = module
    try:
        spec.loader.exec_module(module)
    except Exception:
        sys.modules.pop(module_name, None)
        raise
    return module


def load_graph_bridge(graph_source_path: str, graph_name: str, source_root_path: str) -> LoadedGraphBridge:
    """Build and load a graph bridge while preserving separate staged source files."""

    graph_source = Path(graph_source_path).resolve()
    source_root = Path(source_root_path).resolve()
    if not graph_source.exists():
        raise FileNotFoundError(f"Mojo graph not found: {graph_source}")
    if not source_root.exists():
        raise FileNotFoundError(f"Mojo source root not found: {source_root}")
    if not graph_source.is_relative_to(source_root):
        raise ValueError(f"Graph source {graph_source} is not contained by source root {source_root}")

    template_path = Path(__file__).resolve().parent / "MMMAudioBridge.mojo"
    project_root_parent = Path(__file__).resolve().parents[3]

    graph_id = uuid.uuid4().hex[:8]
    module_name = f"_mmmaudio_graph_bridge_{_sanitize_identifier(graph_name)}_{graph_id}"
    build_dir = tempfile.TemporaryDirectory(prefix=f"{module_name}_")
    build_root = Path(build_dir.name)

    _stage_dependency_graph(graph_source, source_root, build_root)

    shim_dir = build_root / "mmm_audio"
    shim_dir.mkdir(parents=True, exist_ok=True)
    (shim_dir / "__init__.mojo").write_text(MMM_AUDIO_SHIM, encoding="utf-8")

    bridge_path = build_root / f"{module_name}.mojo"
    print(f"Writing package-preserving bridge to {bridge_path}")
    bridge_path.write_text(
        _build_bridge_source(
            template_path=template_path,
            graph_import=_build_graph_import(graph_source, source_root, graph_name),
            graph_name=graph_name,
            module_name=module_name,
        ),
        encoding="utf-8",
    )

    output_so_path = build_root / f"{module_name}.so"
    _compile_bridge_module(
        bridge_source_path=bridge_path,
        output_so_path=output_so_path,
        build_root=build_root,
        project_root_parent=project_root_parent,
    )
    module = _load_extension_module(module_name, output_so_path)
    return LoadedGraphBridge(
        build_dir=build_dir,
        module=module,
        module_name=module_name,
        shared_library_path=output_so_path,
    )


def make_solo_graph(graph_source_path: str, graph_name: str) -> tuple[str, str | None]:
    """Backward-compatible wrapper used by older code paths."""

    loaded = load_graph_bridge(graph_source_path, graph_name, str(Path(graph_source_path).resolve().parent))
    return str(loaded.shared_library_path), None
