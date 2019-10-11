#!/usr/bin/env python3

import sys
import json

import pystache

template = """
<h2><a href="{{url}}">{{title}}</a></h2>
<p>Last update: {{date}}</p>
<p>{{{excerpt}}}</p>
<a href="{{url}}">Read more</a>
"""

renderer = pystache.Renderer()

input = sys.stdin.readline()
index_entries = json.loads(input)
index_entries.reverse()

for entry in index_entries:
    print(renderer.render(template, entry))
