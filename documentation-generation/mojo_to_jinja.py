import jinja2
import os
import json

if __name__ == "__main__":    
    
    os.sys("mojo doc  --json > mmm_dsp_docs.json")
    
    # Load the Jinja2 template
    template_loader = jinja2.FileSystemLoader(searchpath="./")
    template_env = jinja2.Environment(loader=template_loader)
    template = template_env.get_template("mojo_doc_template_jinja.md")
    
    # Render the template with data
    output = template.render(context)
    
    # Print or save the output
    print(output)