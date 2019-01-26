#!python3

from pathlib import Path
import argparse
import subprocess

ATTILA_EXE = "./attila"

INPUT_IMG_FORMATS = ["bmp", "dds", "gif", "hdr", "jpg", "pic",
                     "pkm", "png", "psd", "pvr", "ccz", "svg",
                     "tga", "webp", "pnm", "pug", "crn", "exr",
                     "flif"]


def Check_Input_File_Path(path):
    path_str = str(path)
    globToken = None
    if str(path_str).find("*") > -1:
        globToken = str(path.name)
        path = path.parent
        #print("globtokenless path is " + str(path))
    print(path.stem)
    print(path.suffix)
    if path.is_dir():
        if globToken:
            if globToken == "**":
                return 2
            elif globToken == "*":
                return 1
        else:
            return 1
    elif path.is_file():
        if path.suffix[1:] not in INPUT_IMG_FORMATS:
            return -2
        else:
            return 0
    else:
        return -1
    
# program path, width, atlas output name


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
        sub_textures = []
        if file_path.exists() and file_path.is_file():
            sub_texture_paths = file_path.read_text().splitlines()
            if len(sub_texture_paths) > 0:
                atlas_dir = Path(atlas_base_name)
                if atlas_dir.exists() and not atlas_dir.is_dir():
                    print("Could not create folder as there is a file that is already using that name. Skipping.")
                    continue
                elif not atlas_dir.exists():
                    atlas_dir.mkdir()
                    if not atlas_dir.exists():
                        print("Unable to create folder at '{:s}'. Skipping atlas creation.".format(str(atlas_dir)))
                        continue
                atlas_subtex_dir= atlas_dir / "Sub"
                if not atlas_subtex_dir.exists():
                    atlas_subtex_dir.mkdir()

                print()
                atlas_outdir= str(atlas_dir / "atlas_{:s}.png".format(atlas_base_name))
                json_outdir = atlas_dir / "atlas_{:s}.json".format(atlas_base_name)
                sub_textures = []
                for sub_tex_str in sub_texture_paths:
                    sub_path = Path(sub_tex_str)
                    file_status = Check_Input_File_Path(sub_path)
                    if file_status > -1:
                        #print(type(file_status))
                        #print(file_status)
                        if file_status == 0:
                            #print(str(sub_path))
                            sub_textures.append(sub_path)
                        elif file_status > 0:
                            sub_path = sub_path.parent
                            #print(sub_path)
                            for ext in INPUT_IMG_FORMATS:
                                globPattern = "*.{:s}".format(ext)
                                if file_status == 2:
                                    globPattern = "**/" + globPattern
                                sub_textures += sub_path.glob(globPattern)
                    else:
                        if file_status == -1:
                            print(str(sub_path) + " was an invalid path. Make sure that the folder actually exists.")
                        elif file_status == -2:
                            print(str(sub_path) + " is not an accepted image format for attila.")
                            print("The following formats are accepted: {}"
                                  .format(INPUT_IMG_FORMATS))
                if len(sub_textures) > 1:
                    #print(sub_textures)
                    #ATTILA_ARGS_LIST = (ATTILA_BASE_ARGS.format(
                    #    ATTILA_EXE, int(args.w), atlas_outdir).split())+ ['@{:s}'.format(str(file_path))]
                    ATTILA_ARGS_LIST = (ATTILA_BASE_ARGS.format(
                        ATTILA_EXE, int(args.w), atlas_outdir).split()) + sub_textures
                    print(ATTILA_ARGS_LIST)
                    subprocess.run(ATTILA_ARGS_LIST, stdout=json_outdir.open('w'))
                else:
                    print("Need 2 or more sub textures for an atlas. Atlas creation will be skipped.")
