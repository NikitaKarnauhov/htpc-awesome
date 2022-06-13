// Copied from https://unix.stackexchange.com/a/465846

#define _GNU_SOURCE
#include <X11/Xlib.h>
#include <X11/extensions/XInput2.h>
#include <dlfcn.h>

#include <err.h>

Status XIGrabDevice(
        Display*           dpy,
        int                deviceid,
        Window             grab_window,
        Time               time,
        Cursor             cursor,
        int                grab_mode,
        int                paired_device_mode,
        Bool               owner_events,
        XIEventMask        *mask
){
        int n, is_kb;
        static Status (*XIGrabDevice_orig)(Display*, int, Window, Time,
                Cursor, int, int, Bool, XIEventMask*);
        if(!XIGrabDevice_orig)
                XIGrabDevice_orig = dlsym(RTLD_NEXT, "XIGrabDevice");
        XIDeviceInfo *info = XIQueryDevice(dpy, deviceid, &n);
        is_kb = info->num_classes == 1 && info->classes[0]->type == XIKeyClass;
        /* warnx("trying XIGrabDevice %d %s is_kb=%d %p\n",
                deviceid, info->name, is_kb, XIGrabDevice_orig); */
        XIFreeDeviceInfo(info);
        return is_kb ? 0 :
                XIGrabDevice_orig(dpy, deviceid, grab_window,
                        time, cursor, grab_mode, paired_device_mode,
                        owner_events, mask);
}
