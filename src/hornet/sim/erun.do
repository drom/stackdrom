onbreak {resume}
set PrefMain(colorizeTranscript) 1

# create library
if [file exists hornet] {
    vdel -lib ./hornet -all
}

vlib hornet

vlog -sv -work hornet -f filelist

vsim -novopt hornet.tb

log -r *

if [batch_mode] {
	echo "Batch Mode"
} else {
	do wave.do
}

run 70us

exit
