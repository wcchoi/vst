Visual Timetable
================

This is a simple tool to organize your timetable.

## How to use:

Visit the [Class Schedule &amp; Quota Page](https://w5.ab.ust.hk/wcq/cgi-bin/1310/)

Run the following code
**when you are on the quota page**
by opening the **developer console** of your browser

`$('<script src=https://ihome.ust.hk/~wcchoi/yatta/vst.js></script>').appendTo('body'); void(0);`

In **Internet Explorer 10**, press `F12` and then click `console`, and then paste the code into the textbox with prompt `>>`.

In **Google Chrome/Opera 15**, press `Ctrl-Shift-J` and then paste the code there.

In **Firefox**, press `Ctrl-Shift-K` and then in the bottom of `Console` tab paste the code to the textbox there.

For **Opera 12**, press `Ctrl-Shift-I` and then click the `Console` tab.

For **Safari**, you should have `Developer Menu` enabled (`Preference`->`Advanced`->`Show Developer menu...`), then press `Ctrl-Alt-I`, click `Console` tab.

For other/older browsers please go through the menus to see if there is something called `Console` or `Developer tools` where you can execute javascript code.

When you are done pasting, press `Enter` and a box will show up in the bottom right corner.

You can now add courses to the timetable by clicking the corresponding sections on the course table.

You may close the developer console after that.

--------------

**Alternatively**, you may add a new bookmark/favourite with the address

`javascript:$('<script src=https://ihome.ust.hk/~wcchoi/yatta/vst.js></script>').appendTo('body'); void(0);`

and click the bookmark when you are in quota page. Dragging the above code directly to the bookmark bar will do that (works on Firefox, Chrome, Safari).

Pasting the code to the **address bar** of the browser(excluding Firefox) will also work, but remember to add back the `javascript:` manually in front if the browser(IE, Chrome) chops that off.
