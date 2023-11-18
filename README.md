# JAG_Hively
replay routine and file converter for AHX and Hively tracker module, on Atari Jaguar

run Hively_replay_converter.exe with AHX ou HVL file location
this will create a .streambits file, converted version of this song
take note of ht_defpanleft and ht_defpanright values
and also of number of channels value

then in the Atari Jaguar replay routine source, modify "NB_channels =", "ht_defpanleft =" and "ht_defpanright =" to the values displayed by the converter
change the path in the .incbin at the bottom of the source
assemble compile link
run

