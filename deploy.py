#!/usr/bin/env python

import os, re
os.system('grunt compile')
os.system('cp -r bin/ /Users/mac/Me/web/sae/houzz/1/static/')
index = open('bin/index.html', 'r').read()
temp = re.sub('assets/', '/m/assets/', index)
out = open('/Users/mac/Me/web/sae/houzz/1/mysite/templates/index.html', 'w')
out.write(temp)

