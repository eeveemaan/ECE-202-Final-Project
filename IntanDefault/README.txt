Matlab Real-Time Data Transfer Example Scripts

While real-time data transfer to external applications (for example, Matlab or Python) will always
be limited by an inherent 10-100 ms latency due to USB transfer speeds, there are still some methods
that allow for data to be transferred in near real-time:
a) TCP data transfer, which has been supported since the first RHX public release, and has documentation
and examples available from the Intan website
b) Real-time saving to disk, which has always been an option, but has been improved with version 3.0.5.

A downside to the TCP method is that when multiple channels and higher sample rates are used, the data
rate can reach a bottleneck in TCP transfer rate, and transferred data can begin to back up and fall behind
real-time. This occurs even when transferring data to localhost, and when transferring data via the Internet
further latency can be introduced. In contrast, saving data to disk can be done quite rapidly, and while
other factors like the speed of the external application and the read/write speed of the system's disk are
relevant, this method is likely to be able to keep up with substantially more data than TCP. With version
3.0.5, an option to control write-to-disk latency can be found in the Performance Optimization menu, and
lowering this latency replaces fewer, larger writes with more, smaller writes that will be updated closer
to real-time.

Alongside version 3.0.5 are some example Matlab scripts that demonstrate how an external application can
read saved data in both File Per Channel and File Per Signal Type format. These file formats save data in
binary '.dat' files, which simply contain the raw acquired data (as opposed to 'Traditional' data files
that end with .rhd or .rhs, and are written in large chunks called data blocks which are less suitable
for real-time reading). While these scripts are written in Matlab, any application that can read binary
data (including those written in Python, Julia, R, C++, etc.) could be used to run alongside the RHX software
and read data in close to real-time.

Note: These scripts work with both previously saved data and data that's being acquired in real-time.
By default, Intan RHX software creates a new directory at the time of recording for each session, but this
can be disabled in the 'File Format' dialog of the RHX software, by deselecting 'Create new save directory
with timestamp for each recording'. Note that disabling this allows for previously acquired data to be
overwritten when a new recording session begins, so use this option with care.

These scripts, as written, expect the data that they're reading to be in the same directory.