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
```
