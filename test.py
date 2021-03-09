import random

H = 28

parts = []
wall = ""
bus = ""

with open("./parts.bus", "r") as f:
    part = ""
    for line in f:
        if "[" in line:
            arg = line[1:-2]
            if arg == "wall":
                wall = part
                part = ""
                continue
            parts.append(part)
            part = ""
            continue
        part += line


bus += wall


for i in range(5):
    iPart = random.randint(0, len(parts) - 1)
    bus += parts[iPart]

bus += wall

bus = bus[:-1]

with open("./test.bus", "w") as f:
    f.write(bus)
    
