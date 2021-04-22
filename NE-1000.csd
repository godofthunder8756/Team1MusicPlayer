NE-1000.csd
Written by Aidan Ahern, 2021.

Lol lots of dropped features

<Cabbage>
form caption("Neural Enhancer 1000") size(570,200), colour(0,0,0) pluginid("TScl") style("legacy")
image                       bounds(0, 0, 570, 199), colour(30, 70, 70, 255), , , 

soundfiler bounds(4, 18, 560, 95), channel("beg", "len"), identchannel("filer1"),  colour(0, 0, 0, 255), fontcolour(160, 160, 160, 255), fontcolour:0(160, 160, 160, 255) tablebackgroundcolour(255, 255, 255, 0)
label bounds(5, 2, 561, 16), , align("left"), , fontcolour(200, 200, 200, 255), identchannel("stringbox") text("Select a File...")

rslider bounds(288, 116, 95, 71), channel("freqShift"), range(0, 8, 0, 1, 1), text("Wave Frequency"), colour(50, 90, 90, 255) markercolour(0, 0, 0, 255) valuetextbox(1) trackerinsideradius(0.73)


filebutton bounds(4, 114, 207, 68), text("Select", ""),  channel("filename"), imgfile("On", "outline_library_music_black_24dp.png")
checkbox   bounds(210, 116, 76, 67), , , fontcolour:0(255, 255, 255, 255) channel("PlayStop") imgfile("On", "outline_pause_black_24dp.png")imgfile("Off", "outline_play_arrow_black_24dp.png")

checkbox   bounds(106, 308, 100, 15), channel("lock"), text("Phase Lock"), , colour:1(255, 0, 0, 255) fontcolour:0(255, 255, 255, 255) active(0) visible(0)
checkbox   bounds(106, 320, 100, 15), channel("freeze"), text("Freeze"), , colour:1(173, 216, 230, 255) fontcolour:0(255, 255, 255, 255) active(0) visible(0)

label      bounds(486, 154, 48, 11), text("FFT Size"), fontcolour(255, 255, 255, 255)
combobox   bounds(476, 132, 70, 20), channel("FFTSize"), , value(5), text("32768", "16384", "8192", "4096", "2048", "1024", "512", "256", "128", "64", "32", "16", "8", "4")

rslider    bounds(206, 264, 70, 70), channel("transpose"), range(-48, 48, 0, 1, 1),            colour(50, 90, 90, 255)), trackercolour(255, 255, 255, 255), text("255", "255", "255", "255"), textcolour(192, 192, 192, 255) active(0) visible(0)
rslider    bounds(276, 266, 70, 70), channel("speed"),     range(-2, 2, 1, 1, 0.001),             colour(50, 90, 90, 255),  trackercolour(192, 192, 192, 255), text("Speed"),     textcolour(255, 255, 255, 255) active(0) visible(0)
rslider    bounds(418, 264, 70, 70), channel("AttTim"),    range(0, 5, 0, 0.5, 0.001),       colour(50, 90, 90, 255),  trackercolour(192, 192, 192, 255), text("Att.Tim"),   textcolour(255, 255, 255, 255) active(0) visible(0)
rslider    bounds(350, 266, 70, 70), channel("RelTim"),    range(0.01, 5, 0.05, 0.5, 0.001), colour(50, 90, 90, 255),  trackercolour(192, 192, 192, 255), text("Rel.Tim"),   textcolour(255, 255, 255, 255) active(0) visible(0)
rslider    bounds(490, 264, 70, 70), channel("MidiRef"),   range(0, 127, 60, 1, 1),            colour(50, 90, 90, 255), trackercolour(192, 192, 192, 255),  text("MIDI Ref."), textcolour(255, 255, 255, 255) active(0) visible(0)
rslider    bounds(382, 114, 70, 73), channel("level"),     range(0, 3, 1, 0.5, 0.001),        colour(50, 90, 90, 255),  trackercolour(171, 155, 155, 255), text("Volume"),     textcolour(255, 255, 255, 255)   alpha(0.84) trackerinsideradius(0.84) markercolour(0, 0, 0, 255)

keyboard bounds(6, 264, 560, 65) active(0) visible(0)

</Cabbage>

<CsoundSynthesizer>

<CsOptions>
-n -+rtmidi=NULL -M0
</CsOptions>

<CsInstruments>

;sr is set by the host
ksmps = 64
nchnls = 2
0dbfs=1

massign	0,3

gichans		init	0		; 
giReady		init	0		; flag to indicate function table readiness

giFFTSizes[]	array	32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4	; an array is used to store FFT window sizes

gSfilepath	init	""

opcode FileNameFromPath,S,S		; Extract a file name (as a string) from a full path (also as a string)
 Ssrc	xin				; Read in the file path string
 icnt	strlen	Ssrc			; Get the length of the file path string
 LOOP:					; Loop back to here when checking for a backslash
 iasc	strchar Ssrc, icnt		; Read ascii value of current letter for checking
 if iasc==92 igoto ESCAPE		; If it is a backslash, escape from loop
 loop_gt	icnt,1,0,LOOP		; Loop back and decrement counter which is also used as an index into the string
 ESCAPE:				; Escape point once the backslash has been found
 Sname	strsub Ssrc, icnt+1, -1		; Create a new string of just the file name
	xout	Sname			; Send it back to the caller instrument
endop

instr	1
gkPlayStop	chnget	"PlayStop"
gkloop		chnget	"loop"
gktranspose	chnget	"transpose"
gklevel		chnget	"level"
gkspeed		chnget	"speed"
gklock		chnget	"lock"
gkfreeze	chnget	"freeze"
gkfreeze	=	1-gkfreeze
gkFFTSize	chnget	"FFTSize"
 gSfilepath	chnget	"filename"
 kNewFileTrg	changed	gSfilepath		; if a new file is loaded generate a trigger
 if kNewFileTrg==1 then				; if a new file has been loaded...
  event	"i",99,0,0				; call instrument to update sample storage function table 
 endif  

ktrig	trigger	gkPlayStop,0.5,0
schedkwhen	ktrig,0,0,2,0,-1
endin

instr	99	; load sound file
 gichans	filenchnls	gSfilepath			; derive the number of channels (mono=1,stereo=2) in the sound file
 gitableL	ftgen	1,0,0,1,gSfilepath,0,0,1
 if gichans==2 then
  gitableR	ftgen	2,0,0,1,gSfilepath,0,0,2
 endif
 giReady 	=	1					; if no string has yet been loaded giReady will be zero
 Smessage sprintfk "file(%s)", gSfilepath			; print sound file to viewer
 chnset Smessage, "filer1"

 /* WRITE FILE NAME TO GUI */
 Sname FileNameFromPath	gSfilepath				; Call UDO to extract file name from the full path
 Smessage sprintfk "text(%s)",Sname
 chnset Smessage, "stringbox"

endin

instr	2
 if gkPlayStop==0 then
  turnoff
 endif
 if giReady = 1 then				; i.e. if a file has been loaded
  iAttTim	chnget	"AttTim"		; read in amplitude envelope attack time widget
  iRelTim	chnget	"RelTim"		; read in amplitude envelope attack time widget
  if iAttTim>0 then				; 
   kenv	linsegr	0,iAttTim,1,iRelTim,0
  else								
   kenv	linsegr	1,iRelTim,0			; attack time is zero so ignore this segment of the envelope (a segment of duration zero is not permitted
  endif
  kenv	expcurve	kenv,8			; remap amplitude value with a more natural curve
  aenv	interp		kenv			; interpolate and create a-rate envelope

  kporttime	linseg	0,0.001,0.05
  ktranspose	portk	gktranspose,kporttime
  
  ktrig	changed		gkFFTSize
  if ktrig==1 then
   reinit RESTART
  endif
  RESTART:
  if gichans=1 then
   a1	temposcal	gkspeed*gkfreeze, gklevel, semitone(ktranspose), gitableL, gklock, giFFTSizes[i(gkFFTSize)-1]
  	outs	a1*aenv,a1*aenv
  elseif gichans=2 then
   a1	temposcal	gkspeed*gkfreeze, gklevel, semitone(ktranspose), gitableL, gklock, giFFTSizes[i(gkFFTSize)-1]
   a2	temposcal	gkspeed*gkfreeze, gklevel, semitone(ktranspose), gitableR, gklock, giFFTSizes[i(gkFFTSize)-1]
   ifftSize = 1024
    ioverlap = ifftSize / 4
    iwinsize = ifftSize
    iwinshape = 1
    ffta1 pvsanal a1, ifftSize, ioverlap, iwinsize, iwinshape
    fShifted pvshift ffta1, chnget:k("freqShift"), 100
    a2 pvsynth fShifted
  	outs	a1,a2
 endif
endif

 ; print scrubber
 kscrubber	phasor	(gkspeed*gkfreeze*sr)/ftlen(gitableL)
 if(metro(20)==1) then
  Smessage sprintfk "scrubberposition(%d)", kscrubber*ftlen(gitableL)
  chnset Smessage, "filer1"
 endif

endin




instr	3	; midi triggered instrument
 if giReady = 1 then						; i.e. if a file has been loaded
  icps	cpsmidi							; read in midi note data as cycles per second
  iamp	ampmidi	1						; read in midi velocity (as a value within the range 0 - 1)
  iMidiRef	chnget	"MidiRef"				; MIDI unison reference note
  iFrqRatio		=	icps/cpsmidinn(iMidiRef)	; derive playback speed from note played in relation to a reference note (MIDI note 60 / middle C)
 
  iAttTim	chnget	"AttTim"		; read in amplitude envelope attack time widget
  iRelTim	chnget	"RelTim"		; read in amplitude envelope attack time widget
  if iAttTim>0 then				; 
   kenv	linsegr	0,iAttTim,1,iRelTim,0
  else								
   kenv	linsegr	1,iRelTim,0			; attack time is zero so ignore this segment of the envelope (a segment of duration zero is not permitted
  endif
  kenv	expcurve	kenv,8			; remap amplitude value with a more natural curve
  aenv	interp		kenv			; interpolate and create a-rate envelope
  
  ktrig	changed		gkFFTSize
  if ktrig==1 then
   reinit RESTART
  endif
  RESTART:
  if gichans=1 then
   a1	temposcal	gkspeed*gkfreeze, gklevel*iamp, iFrqRatio, gitableL, gklock, giFFTSizes[i(gkFFTSize)-1]
  	outs	a1*aenv,a1*aenv
  elseif gichans=2 then
   a1	temposcal	gkspeed*gkfreeze, gklevel*iamp, iFrqRatio, gitableL, gklock, giFFTSizes[i(gkFFTSize)-1]
   a2	temposcal	gkspeed*gkfreeze, gklevel*iamp, iFrqRatio, gitableR, gklock, giFFTSizes[i(gkFFTSize)-1]
  	outs	a1*aenv,a2*aenv
  endif
 endif
endin

</CsInstruments>  

<CsScore>
i 1 0 10000
</CsScore>

</CsoundSynthesizer>
