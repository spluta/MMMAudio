from jinja2 import Template
import json
import argparse
import sys
from pathlib import Path

def render_template_str(template_str, context):
    """Render a Jinja2 template string with the given context."""
    template = Template(template_str)
    return template.render(**context)

def process_json_files(input_dir, output_dir, template_path):
    """Process all JSON files in input_dir and render them to markdown in output_dir."""
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    template_file = Path(template_path)
    
    # Validate input directory
    if not input_path.exists():
        print(f"Error: Input directory '{input_dir}' does not exist")
        return False
    
    if not input_path.is_dir():
        print(f"Error: '{input_dir}' is not a directory")
        return False
    
    # Validate template file
    if not template_file.exists():
        print(f"Error: Template file '{template_path}' does not exist")
        return False
    
    # Create output directory if it doesn't exist
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Load the template
    try:
        with open(template_file, 'r', encoding='utf-8') as f:
            template_content = f.read()
    except Exception as e:
        print(f"Error reading template file '{template_path}': {e}")
        return False
    
    # Find all JSON files in input directory
    json_files = list(input_path.glob("*.json"))
    
    if not json_files:
        print(f"Warning: No JSON files found in '{input_dir}'")
        return True
    
    print(f"Found {len(json_files)} JSON files to process")
    
    # Process each JSON file
    processed_count = 0
    error_count = 0
    
    for json_file in json_files:
        try:
            print(f"Processing: {json_file.name}")
            
            # Load JSON data
            with open(json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Render the template
            rendered_markdown = render_template_str(template_content, data)
            
            # Create output filename (replace .json with .md)
            output_filename = json_file.stem + '.md'
            output_file = output_path / output_filename
            
            # Write the rendered markdown
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(rendered_markdown)
            
            print(f"  Generated: {output_file}")
            processed_count += 1
            
        except json.JSONDecodeError as e:
            print(f"  Error: Invalid JSON in '{json_file}': {e}")
            error_count += 1
        except Exception as e:
            print(f"  Error processing '{json_file}': {e}")
            error_count += 1
    
    print(f"\nProcessing complete:")
    print(f"  Successfully processed: {processed_count} files")
    print(f"  Errors: {error_count} files")
    
    return error_count == 0

def main():
    """Main function with argument parsing."""
    parser = argparse.ArgumentParser(
        description="Convert Mojo documentation JSON files to Markdown using Jinja2 templates",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s -i ./json_docs -o ./markdown_docs
  %(prog)s --input-dir /path/to/json --output-dir /path/to/output --template custom_template.md
        """
    )
    
    parser.add_argument(
        '-i', '--input-dir',
        required=True,
        help='Directory containing JSON files from "mojo doc" output'
    )
    
    parser.add_argument(
        '-o', '--output-dir', 
        required=True,
        help='Directory where rendered Markdown files will be written'
    )
    
    parser.add_argument(
        '-t', '--template',
        default='mojo_doc_template_jinja.md',
        help='Path to Jinja2 template file (default: mojo_doc_template_jinja.md)'
    )
    
    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Enable verbose output'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        print(f"Input directory: {args.input_dir}")
        print(f"Output directory: {args.output_dir}")
        print(f"Template file: {args.template}")
        print()
        
    # Clear docs directory before regenerating
    docs_dir = Path(args.output_dir)
    if docs_dir.exists() and docs_dir.is_dir():
        for file in docs_dir.glob("*.md"):
            try:
                file.unlink()
                if args.verbose:
                    print(f"Deleted old file: {file}")
            except Exception as e:
                print(f"Error deleting file '{file}': {e}")
    
    # Process the files
    success = process_json_files(args.input_dir, args.output_dir, args.template)
    
    if not success:
        sys.exit(1)

if __name__ == "__main__":
    main()