#!/usr/bin/env python3
# pico-mbine 2020.07.26
# by Joe Jarvis

# Separate .p8 files for easy external editing
# Combine them again to run in pico-8

# Usage:

# ./pico-mbine.py export {file}
#   separates a pico-8 cart to a local folder with the same name as the cart
# ./pico-mbine.py import {file}
#   combines a folder of separated files to a pico-8 cart

import os
import argparse

def readFile(file):
    with open(file, "r") as f:
        return f.read()

def writeFile(file, contents):
    with open(file, "w") as f:
        f.write(contents)

# location of pico 8 carts
pico_dir = os.path.expanduser("~/.lexaloffle/pico-8/carts/")

# get args
ap = argparse.ArgumentParser()
ap.add_argument("action", nargs=1, choices=["import", "export"])
ap.add_argument("file", nargs=1)
args = ap.parse_args()

# the file name for cart/folder
cart_name = args.file[0]
folder_name = args.file[0].split(".")[0]
# the absolute path of the real cart
cart = os.path.join(pico_dir, cart_name)

# extract pico cart to separate files
if args.action[0] == "export" and os.path.isfile(cart):
    # if file exists
    print("Loading file: " + cart)
    contents = readFile(cart)
    if not os.path.isdir(folder_name):
        print("Creating {} folder".format(folder_name))
        os.mkdir(folder_name)

    currentSection = ""
    __head__ = ""
    sections = {
        "__lua__": [""],
        "__gfx__": "",
        "__label__": "",
        "__map__": "",
        "__sfx__": "",
        "__music__": ""
    }
    luaIdx = 0

    for line in contents.splitlines():
        # change what the current section is
        if line in sections:
            currentSection = line
        elif currentSection == "":
            # add lines to head section if haven't found a section yet
            __head__ += line + "\n"
        else:
            if currentSection == "__lua__":
                # create space for file if it doesn't exist yet
                if luaIdx >= len(sections[currentSection]):
                    sections[currentSection].append("")
                # move to new file if file separator is found
                if line == "-->8":
                    luaIdx += 1
                # add current line to file
                else:
                    sections[currentSection][luaIdx] += line + "\n"
            else:
                # add current line to the current section's file
                sections[currentSection] += line + "\n"

    print("Writing file: __head__")
    # write head to __head__ file
    writeFile(os.path.join(folder_name, "__head__"), __head__)
    # loop through sections
    for section in sections:
        if section == "__lua__":
            # loop through each lua file
            for i in range(len(sections["__lua__"])):
                print("Writing file: {}.p8.lua".format(i))
                # write lua file with tab index as file name
                writeFile(os.path.join(folder_name, str(i) + ".p8.lua"), sections[section][i])
        else:
            print("Writing file: " + section)
            # write section contents to section
            writeFile(os.path.join(folder_name, section), sections[section])

    print("\nDone!")
# combine files to pico cart
elif args.action[0] == "import" and os.path.isdir(folder_name):
    # create var for storing combined pico cart contents
    pico = ""
    print("Loading file: __head__")
    # add head to cart
    pico += readFile(os.path.join(folder_name, "__head__"))

    # add lua section
    pico += "__lua__\n"
    number = 0
    while True:
        # loop through numbers numbers until a non existant file is found
        file = os.path.join(folder_name, str(number) + ".p8.lua")
        if not os.path.isfile(file):
            break;

        # add file separator if not first tab
        if number > 0:
            pico += "-->8\n"
        print("Loading file: " + str(number) + ".p8.lua")
        # add lua file to cart
        pico += readFile(file)
        number += 1

    # add all other sections to cart
    for section in ["__gfx__", "__label__", "__map__", "__sfx__", "__music__"]:
        pico += section + "\n"
        print("Loading file: " + section)
        pico += readFile(os.path.join(folder_name, section))

    # write to cart
    print ("Writing file: " + cart_name)
    writeFile(cart_name, pico)
    print("Writing file: " + cart)
    writeFile(cart, pico)

    print("\nDone!")
