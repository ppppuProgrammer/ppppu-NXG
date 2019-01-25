#!python3

from pathlib import Path
import argparse
import subprocess

ATTILA_EXE="./attila"

#width, atlas output name
ATTILA_BASE_ARGS="{:s} --enable-edge --enable-pot --enable-width {:d} {:s}"

if __name__ == '__main__':
    argParser = argparse.ArgumentParser(description="Packs textures into an texture atlas. Requires attila (https://github.com/r-lyeh-archived/attila)")
    argParser.add_argument("i", nargs='+', help="Input text file to read from")
    argParser.add_argument("-w", default="0", help="Change width of created atlas file")
    args = argParser.parse_args()

    
    for atlas_txt_file in args.i:
        file_path = Path(atlas_txt_file)
        print("Reading '{:s}'".format(str(file_path)))
        atlas_base_name = str(file_path.stem)
        if file_path.exists() and file_path.is_file():
            sub_texture_paths = file_path.read_text().splitlines()
            #No point packing if there is only one sub texture
            if len(sub_texture_paths) > 1:
                atlas_dir = Path(atlas_base_name)
                if atlas_dir.exists() and not atlas_dir.is_dir():
                    print("Could not create folder as there is a file that is already using that name. Skipping.")
                    continue
                elif not atlas_dir.exists():
                    atlas_dir.mkdir()
                    if not atlas_dir.exists():
                        print("Unable to create folder at '{:s}'. Skipping atlas creation.".format(str(atlas_dir)))
                        continue

                print()
                atlas_outdir= str(atlas_dir / "atlas_{:s}.png".format(atlas_base_name))
                json_outdir = atlas_dir / "atlas_{:s}.json".format(atlas_base_name)
                
                #sub_tex_list = []
                #Create string for the sub textures paths
                #for sub_tex in sub_texture_paths:
                #    sub_tex_list.append("'{:s}'".format(sub_tex))
                #Debug: Make sure a valid command was created.
                ATTILA_ARGS_LIST = (ATTILA_BASE_ARGS.format(ATTILA_EXE, int(args.w), atlas_outdir).split()) + ['@{:s}'.format(str(file_path))]
                #print(ATTILA_ARGS_LIST)
                subprocess.run(ATTILA_ARGS_LIST, stdout=json_outdir.open('w'))
            else:
                print("Need 2 or more sub textures for an atlas. Atlas creation will be skipped.")
                        
            
            
