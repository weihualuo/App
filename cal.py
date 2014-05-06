
def cal(width):
    n = 6
    if width <= 1024: n = 5 
    if width <= 800: n = 4 
    if width <= 630: n = 3 
    if width <= 420: n = 2 
    if width >= 850: width -= 60 
    width -= 4
    
    w = width/n*0.98
    return w
    

width = [320, 360, 384, 424, 640, 853, 960, 966, 1024, 1280]
for w in width:
    print w, cal(w)    
    
        