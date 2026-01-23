# Usage

```bash
docker run \
   -it \
   --rm \
   -v $(pwd):/openscad \
   -u $(id -u ${USER}):$(id -g ${USER}) \
   openscad/openscad:latest \
   openscad \
       -D "device_height=37.75" \
       -D "device_width=112.32" \
       -D "device_depth=111.59" \
       -o geekom-mount.stl generic-mount.scad
docker run \
   -it \
   --rm \
   -v $(pwd):/openscad \
   -u $(id -u ${USER}):$(id -g ${USER}) \
   openscad/openscad:latest \
   openscad \
       -D "device_height=25" \
       -D "device_width=160" \
       -D "device_depth=78.39" \
       -o ugreen-displaylink-mount.stl generic-mount.scad
docker run \
   -it \
   --rm \
   -v $(pwd):/openscad \
   -u $(id -u ${USER}):$(id -g ${USER}) \
   openscad/openscad:latest \
   openscad \
       -D "device_height=38.03" \
       -D "device_width=140.53" \
       -D "device_depth=67.36" \
       -o kvm-switch-mount.stl generic-mount.scad
docker run \
   -it \
   --rm \
   -v $(pwd):/openscad \
   -u $(id -u ${USER}):$(id -g ${USER}) \
   openscad/openscad:latest \
   openscad \
       -D "device_height=23.18" \
       -D "device_width=63.66" \
       -D "device_depth=98" \
       -o geekom-power-brick-mount.stl generic-mount.scad
docker run \
   -it \
   --rm \
   -v $(pwd):/openscad \
   -u $(id -u ${USER}):$(id -g ${USER}) \
   openscad/openscad:latest \
   openscad \
       -D "device_height=25.75" \
       -D "device_width=75.45" \
       -D "device_depth=150" \
       -o caldigit-power-brick-mount.stl generic-mount.scad
```
