am_dyn_dles
===========

A helper script for the amanda backup suite (1).

The idea is that you want to backup very dynamic data.
In my case it is content generated by the mythtv software.

The data is bigger than one tape and it changes every day, so it is difficult to define matching DLEs to fit on tape.

The am_dyn_dles script is usually called right before running amdump and generates DLEs using include lists. It adds items to the include lists until the estimated size of the DLE is just under the configured $TARGET_DLE_SIZE.

By doing so amanda should be able to fit at least one DLE to the available tape media.

-

This is an early draft and by no way finished, I just want to share it for others to use and improve.

Stefan G. Weichinger

(1) http://www.amanda.org
