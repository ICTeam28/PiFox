#!/usr/bin/python2

"""
This file is part of the Team 28 Project
Licensing information can be found in the LICENSE file
(C) 2014 The Team 28 Authors. All rights reserved.
"""

from PIL import Image
import struct
import sys
import os
import argparse


def main():
    # Parse arguments
    parser = argparse.ArgumentParser(description='Converts an image to binary')
    parser.add_argument('file', metavar='N', type=str, nargs=1,
                        help='Input file')
    parser.add_argument('-o', '--out', help='output .bin file')
    parser.add_argument('-d', '--add-depth', action='store_true')

    # Get file names
    args = parser.parse_args()
    in_path = args.file[0]
    root, ext = os.path.splitext(in_path)
    out_path = args.out if args.out is not None else root + ".bmap"

    # Read image
    image = Image.open(in_path)
    f = open(out_path, 'wb')

    # Write size
    width, height = image.size
    f.write(struct.pack('<II', height, width))

    # Write data
    for y in xrange(height):
        for x in xrange(width):
            r, g, b, a = image.getpixel((x, y))

            assert 0 <= r < 256
            assert 0 <= g < 256
            assert 0 <= b < 256
            assert 0 <= a < 256

            f.write(struct.pack('<BBBB', r, g, b, a))
            if args.add_depth:
                f.write(struct.pack('<f', 0x38f00000))

    f.flush()
    f.close()


if __name__ == '__main__':
    main()
