; OK - test de lecture de la ram dsp en .w : lit toujours 32 bits calé sur un multiple de 4
; - reste il un problème de son avec l'instrument bizarre sur forsaken ?
; OK - flag arret 
; OK - variabiliser la dest de triangle et sawtooth
; OK - variabiliser la routine suivante après triangle et sawtooth
; OK - ajouter les champs dans les datas : OK : record I2S 			et 					record datas d'un channel
; OK - en C, ajouter le bit pour RM : condition = difficile
; OK - en C, ajouter les datas pour RM
; OK - lire les datas pour RM, remplir les champs
; OK - convertir les champs dans DSP_genere_wave__boucle
; - utiliser les champs dans 2IS



; - Ring Modulation : bits en plus + comment faire ?


; OK - panning : bits aussi en plus pour stocker voice->vc_Pan sur 8 bits , de -128 a 127 => si voice->vc_Pan<>voice->old_vc_Pan => nouvelle valeur de panning // valeur de panning left et right sur 8 bits // 0-255
		;  OK pour chaque voie il faut un panning // 8 bits * volume sur 6 bits // * panning 0-255 // >>7 

; panning : 
	; gauche : 1 4 5 8 9  12 13 16
	; droite : 2 3 6 7 10 11 14 15


; hively replay N channels en streaming + AHX
;
; OK - cadre 68000 + DSP
; OK - streambits version ( un octet décrit ce que la suite doit changer comme variables)
; OK - routine d'init au dsp 
; - lire N channels et remplir les datas pour chaque channel
; - generer N buffers
; OK - mixer N channels en addition avec des SAT en fin
; OK refaire une structure integrant les valeurs venant du streaming + les valeurs necessaire pour I2S

; 8 bits :
;				- bit 7 : flag panning stereo : 
;				- bit 6 : flag vc_AudioVolume : 6 bits
;				- bit 5 : flag vc_Waveform : 2 bits
;				- bit 4 : flag vc_SquarePos : 6 bits
;				- bit 3 : flag vc_WaveLength : 3 bits
;				- bit 2 : flag vc_FilterPos : 6 bits
;				- bit 1 : flag vc_AudioPeriod : 12 bits
;				( - bit 0 : flag vc_RingNewWaveform : pas utilisé : vc_Waveform+vc_WaveLength+vc_AudioPeriod = 1+3+12=16 bits )






;CC (Carry Clear) = %00100
;CS (Carry Set)   = %01000
;EQ (Equal)       = %00010
;MI (Minus)       = %11000
;NE (Not Equal)   = %00001
;PL (Plus)        = %10100
;HI (Higher)      = %00101
;T (True)         = %00000



NB_channels = 4					; nb voies dans le fichier hively d'origine et donc dans le fichier .streambits
channel1_ON_OFF=	1
channel2_ON_OFF=	1
channel3_ON_OFF=	1
channel4_ON_OFF=	1
channel5_ON_OFF=	1
channel6_ON_OFF=	1
channel7_ON_OFF=	1
channel8_ON_OFF=	1
channel9_ON_OFF=	1
channel10_ON_OFF=1
ht_defpanleft = 64
ht_defpanright = 193
speed_multiplier=0		; venant du code C de conversion vers streaming



;-----------------------------------
display_time=1				; jaune=68000 / vert = DSP

AHX_nb_bits_virgule_increment_period		.equ			16		; mini freq = 16000 // freq amiga = 32000 // 32000/16000=2 => 2 bits // 128=>7 bits // 9 bits + signe : entiere = 10 bits
DSP_Audio_frequence					.equ			37000				; real hardware needs lower sample frequencies than emulators 





;-----------------------------------

	include	"jaguar.inc"
	
; --------------------- DSP
DSP_STACK_SIZE	equ		64	; long words
DSP_USP			equ		(D_ENDRAM-(4*DSP_STACK_SIZE))
DSP_ISP			equ		(DSP_USP-(4*DSP_STACK_SIZE))
; --------------------- DSP



; ----------------------------
; parametres affichage
;ob_liste_originale			equ		(ENDRAM-$4000)							; address of list (shadow)
ob_list_courante			equ		((ENDRAM-$4000)+$2000)				; address of read list
nb_octets_par_ligne			equ		320
nb_lignes					equ		256



; ----------------------------
.opt "~Oall"

.text
.68000



	move.l		#$70007,G_END
	move.l		#$70007,D_END
	move.l		#INITSTACK, sp	
	move.w		#801,VI			; stop VI
			

	lea			DEBUT_BSS,a0
	lea			FIN_RAM,a1
	moveq		#0,d0
	
boucle_clean_BSS:
	move.b		d0,(a0)+
	cmp.l		a0,a1
	bne.s		boucle_clean_BSS


	move.l	#0,D_CTRL
; copie du code DSP dans la RAM DSP

	lea		code_DSP_debut,A0
	lea		D_RAM,A1
	move.l	#code_DSP_fin-DSP_base_memoire,d0
	lsr.l	#2,d0
	sub.l	#1,D0
boucle_copie_bloc_DSP:
	move.l	(A0)+,(A1)+
	dbf		D0,boucle_copie_bloc_DSP
	
; gere les mutes de channels pour test/debug
	move.l		#channel1_ON_OFF,HIVELY_datas_channels+(0*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	move.l		#channel2_ON_OFF,HIVELY_datas_channels+(1*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	move.l		#channel3_ON_OFF,HIVELY_datas_channels+(2*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	move.l		#channel4_ON_OFF,HIVELY_datas_channels+(3*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off

	.if				NB_channels>4
		move.l		#channel5_ON_OFF,HIVELY_datas_channels+(4*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	.if				NB_channels>5
		move.l		#channel6_ON_OFF,HIVELY_datas_channels+(5*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	.if				NB_channels>6
		move.l		#channel7_ON_OFF,HIVELY_datas_channels+(6*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	.if				NB_channels>7
		move.l		#channel8_ON_OFF,HIVELY_datas_channels+(7*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	.if				NB_channels>8
		move.l		#channel9_ON_OFF,HIVELY_datas_channels+(8*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	.if				NB_channels>9
		move.l		#channel10_ON_OFF,HIVELY_datas_channels+(9*DSP_offset_vc__total)+DSP_offset_vc_channel_on_off
	.endif
	
	
	bsr				setup_panning_voices
	
		
	move.w		#$000,JOYSTICK


;check ntsc ou pal:
	moveq		#0,d0
	move.w		JOYBUTS ,d0
	move.l		#26593900,frequence_Video_Clock			; PAL
	move.l		#415530,frequence_Video_Clock_divisee
	btst		#4,d0
	beq.s		jesuisenpal
jesuisenntsc:
	move.l		#26590906,frequence_Video_Clock			; NTSC
	move.l		#415483,frequence_Video_Clock_divisee
jesuisenpal:



	move.w		#%0000011011000111, VMODE			; 320x256
	move.w		#$100,JOYSTICK



    bsr     InitVideo               	; Setup our video registers.


	;bsr		creer_Object_list
	;jsr     copy_olist              	; use Blitter to update active list from shadow

	move.l	#ob_list_courante,d0					; set the object list pointer
	swap	d0
	move.l	d0,OLP

	lea		CLUT,a2
	move.l	#255-2,d7
	moveq	#0,d0
	
copie_couleurs:
	move.w	d0,(a2)+
	addq.l	#5,d0
	dbf		d7,copie_couleurs

	lea		CLUT+2,a2
	move.w	#$F00F,(a2)+
	

	move.l	#ob_list_courante,d0					; set the object list pointer
	swap	d0
	move.l	d0,OLP

	
	.if				1=1
	move.l  #VBL,LEVEL0     	; Install 68K LEVEL0 handler
	move.w  a_vde,d0                	; Must be ODD
	ori.w   #1,d0
	move.w  d0,VI

	move.w  #%01,INT1                 	; Enable video interrupts 11101


	and.w   #%1111100011111111,sr				; 1111100011111111 => bits 8/9/10 = 0
	and.w   #$f8ff,sr

	.endif



; ------------------------------------------------------------------------
; -----------


	move.l		#1,AHX_DSP_flag_timer1
	
; launch DSP
	move.l	#REGPAGE,D_FLAGS
	move.l	#DSP_routine_init_DSP,D_PC
	move.l	#DSPGO,D_CTRL


; ------------------------
; CLS
	moveq	#0,d0
	bsr		print_caractere

	move.b		#181,couleur_char
	
	lea			chaine_V3,a0
	bsr			print_string

; ligne suivante
	moveq		#10,d0
	bsr			print_caractere
	
; afficher nb channels
	lea			chaine_nb_channels,a0
	bsr			print_string
	moveq		#NB_channels,d0
	bsr				print_nombre_2_chiffres
; ligne suivante
	moveq		#10,d0
	bsr			print_caractere
	

; afficher frequence de replay timer 1
	lea			chaine_frequence,a0
	bsr			print_string

	moveq		#speed_multiplier*4,d1
	lea				table_chaines_hertz,a0
	move.l		(a0,d1.w),a0
	bsr			print_string
	

; -----------
; ------------------------------------------------------------------------


; affichage frequence réelle I2S
	lea			chaine_freq,a0
	bsr			print_string
	move.l		DSP_frequence_de_replay_reelle_I2S,d0
	bsr			print_nombre_5_chiffres
	lea			chaine_HZ,a0
	bsr			print_string

; calcul RAM DSP
	move.l		#D_ENDRAM,d0
	sub.l		debut_ram_libre_DSP,d0
	
	move.l		a0,-(sp)
	lea			chaine_RAM_DSP,a0
	bsr			print_string
	move.l		(sp)+,a0
	
	bsr			print_nombre_4_chiffres
; ligne suivante
	moveq		#10,d0
	bsr			print_caractere



; affiche ram centrale utilisée
	lea			chaine_centrale,a0
	bsr			print_string

	move.l		#FIN_RAM_before_screen-$4000,d0
	bsr			print_nombre_5_chiffres
	

; ligne suivante
	moveq		#10,d0
	bsr			print_caractere


	

; ligne suivante
	moveq		#10,d0
	bsr			print_caractere

	lea			chaine_start_playing,a0
	bsr			print_string

	move.l		#0,numero_de_frame

; test d'arret du dsp
;	move.w		#(60*5),d7
;wait_dsp_frame:	
;		move.l		numero_de_frame_DSP,d0
;main_wait_dsp2:		
;		cmp.l		numero_de_frame_DSP,d0
;		beq.s		main_wait_dsp2
;
;		dbf				d7,wait_dsp_frame
	;move.l		#1,DSP_flag_replay_ON_OFF

; test manipulation ram dsp en .w
;wait_test68k:
;	move.l				DSP_memory_W_test_resultat,d1
;	cmp.l				#0,d1
;	beq.s				wait_test68k
;	
;; partie haute original
;	move.l				DSP_memory_W_test_original,d1
;	move.l				d1,d0
;	swap				d0
;	and.l					#$FFFF,d0
;	bsr						print_nombre_hexa_4_chiffres
;	move.l				d1,d0
;	and.l					#$FFFF,d0
;	bsr						print_nombre_hexa_4_chiffres
;; ligne suivante
;	moveq		#10,d0
;	bsr			print_caractere
;
;; partie haute original
;	move.l				DSP_memory_W_test_resultat,d1
;	move.l				d1,d0
;	swap				d0
;	and.l					#$FFFF,d0
;	bsr						print_nombre_hexa_4_chiffres
;	move.l				d1,d0
;	and.l					#$FFFF,d0
;	bsr						print_nombre_hexa_4_chiffres
;; ligne suivante
;	moveq		#10,d0
;	bsr			print_caractere


	;stop		#$2300
;------------------------------------------------------------
main:
		;bra.s		main
		move.l		numero_de_frame_DSP,d0
main_wait_dsp:		
		cmp.l		numero_de_frame_DSP,d0
		beq.s		main_wait_dsp

		cmp.l			#(317-1),numero_de_frame_DSP
		blt.s			.ok
		nop
		nop
.ok:		

	;lea		binPeriodTable,a0


		move.l		numero_de_frame,d0
		addq.l		#1,d0
		cmp.l		#9999,d0
		ble.s		.okok1
		move.l		#0,d0
.okok1:		
		move.l		d0,numero_de_frame
		bsr			print_nombre_4_chiffres
	
		moveq	#32,d0
		bsr			print_caractere
		
		
; 2eme compteur
		move.l		numero_de_frame_DSP,d0
		cmp.l		#9999,d0
		ble.s		.okok2
		move.l		#0,d0
.okok2:		
		bsr			print_nombre_4_chiffres
		moveq		#10,d0					; retour chariot
		bsr			print_caractere

		subq.w		#8,curseur_y
	;	subq.w		#8,curseur_y

		bra			main
;------------------------------------------------------------

	.phrase
numero_de_frame:		dc.l			0



setup_panning_voices:

		lea				AHX_enregistrements_N_voies,a0
		lea				Hively_panning_left,a1
		lea				Hively_panning_right,a2
		
; 4 premieres voies
		move.l		#ht_defpanleft,d1
		move.l		#ht_defpanright,d2
		moveq		#0,d3

; voie 1 gauche
		move.b		(a1,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*0)(a0)
;voie 1 droite
		move.b		(a2,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*0)(a0)
; voie 2 gauche
		move.b		(a1,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*1)(a0)
;voie 2 droite
		move.b		(a2,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*1)(a0)
; voie 3 gauche
		move.b		(a1,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*2)(a0)
;voie 3 droite
		move.b		(a2,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*2)(a0)
; voie 4 gauche
		move.b		(a1,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*3)(a0)
;voie 4 droite
		move.b		(a2,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*3)(a0)

index2				set				4
		.if				NB_channels>4
; voie 5 gauche
		move.b		(a1,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
;voie 5 droite
		move.b		(a2,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
; voie 6 gauche
		move.b		(a1,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
;voie 6 droite
		move.b		(a2,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
		.endif
index2				set				index2+2
		.if				NB_channels>6
; voie 7 gauche
		move.b		(a1,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
;voie 7 droite
		move.b		(a2,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
; voie 8 gauche
		move.b		(a1,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
;voie 8 droite
		move.b		(a2,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
		.endif
index2				set				index2+2
		.if				NB_channels>8
; voie 9 gauche
		move.b		(a1,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
;voie 9 droite
		move.b		(a2,d1.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*index2)(a0)
; voie 10 gauche
		move.b		(a1,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_left*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
;voie 10 droite
		move.b		(a2,d2.w),d3
		move.l		d3,(index_AHX_enregistrements_N_voies__I2S__panning_right*4)+(AHX_enregistrements_N_voies__I2S__taille_totale*(index2+1))(a0)
		.endif



		rts
;------------------------------------------------------------
;-------------------------------------
;
;     DSP
;
;-------------------------------------
;------------------------------------------------------------





	.phrase

code_DSP_debut:
	.dsp
	.org	D_RAM

; HIVELY_datas_channels
DSP_index_vc_AudioVolume		.equ			0
DSP_index_vc_Waveform				.equ			1
DSP_index_vc_SquarePos			.equ			2
DSP_index_vc_WaveLength			.equ			3
DSP_index_vc_FilterPos			.equ			4
DSP_index_vc_AudioPeriod		.equ			5
DSP_index_vc_channel_on_off	.equ			6
DSP_index_vc_RingWaveform		.equ			7
DSP_index_vc_RingAudioPeriod	.equ		8
DSP_index_vc__total			.equ			9

DSP_offset_vc_AudioVolume				.equ				0
DSP_offset_vc_Waveform					.equ				4
DSP_offset_vc_SquarePos					.equ				8
DSP_offset_vc_WaveLength				.equ				12
DSP_offset_vc_FilterPos					.equ				16
DSP_offset_vc_AudioPeriod				.equ				20
DSP_offset_vc_channel_on_off		.equ				24
DSP_offset_vc_RingWaveform			.equ				28
DSP_offset_vc_RingAudioPeriod	.equ				32
DSP_offset_vc__total					.equ			36




; #AHX_enregistrements_N_voies
index_AHX_enregistrements_N_voies__I2S__offset=0
index_AHX_enregistrements_N_voies__I2S__increment=1
index_AHX_enregistrements_N_voies__I2S__mask_bouclage=2
index_AHX_enregistrements_N_voies__I2S__buffer=3
index_AHX_enregistrements_N_voies__I2S__panning_left=4
index_AHX_enregistrements_N_voies__I2S__panning_right=5
index_AHX_enregistrements_N_voies__I2S__offset__RM=6
index_AHX_enregistrements_N_voies__I2S__increment__RM=7
index_AHX_enregistrements_N_voies__I2S__buffer__RM=8
AHX_enregistrements_N_voies__I2S__taille_totale=9*4





DSP_base_memoire:








;------------------------------------------------------------
AHX__I2S__tmp_1																					.equr		R0
AHX__I2S__tmp_2																					.equr		R1
; voie G
AHX__I2S__offset_entier_et_virgule__voie_G					.equr		R2
AHX__I2S__increment_entier_et_virgule__voie_G			.equr		R3
AHX__I2S__mask_bouclage_voie_G												.equr		R4
AHX__I2S__adresse_buffer_sample__voie_G							.equr		R5
; voie G
AHX__I2S__offset_entier_et_virgule__voie_D					.equr		R6
AHX__I2S__increment_entier_et_virgule__voie_D			.equr		R7
AHX__I2S__mask_bouclage_voie_D												.equr		R8
AHX__I2S__adresse_buffer_sample__voie_D							.equr		R9


AHX__I2S__adresse_code_boucle												.equr		R10
AHX__I2S__sample_gauche																.equr		R11
AHX__I2S__sample_droite																.equr		R12
; R13
AHX_I2S_pointeur_datas_voie_en_cours_G							.equr		R14
AHX_I2S_pointeur_datas_voie_en_cours_D							.equr		R15
AHX__I2S__compteur_nb_voie														.equr		R16
AHX_I2S_increment_taille_AHX_enregistrements_N_voies		.equr			R17
AHX_I2S_pointeur_DAC_voie_G														.equr		R18							; init par moveta
AHX_I2S_pointeur_DAC_voie_D														.equr		R19							; init par moveta
; R20
AHX__I2S__tmp_3											.equr		R21
AHX__I2S__tmp_4											.equr		R22
AHX__I2S__tmp_sample_G						.equr		R23
AHX__I2S__tmp_sample_D						.equr		R24
AHX__I2S__routine_actuelle				.equr												R28
AHX__I2S__save_flags																		.equr		R29
;R30=used
;R31=stack


; CPU interrupt
	.rept	8
		nop
	.endr
; I2S interrupt
	move		AHX__I2S__routine_actuelle,AHX__I2S__tmp_1			; 2 octets
	;movei	#AHX_I2S_N_voies,AHX__I2S__tmp_1						; 6 octets
	movei	#D_FLAGS,r30											; 6 octets
	jump		(AHX__I2S__tmp_1)													; 2 octets
	load		(r30),AHX__I2S__save_flags	; read flags								; 2 octets = 16 octets
	nop
	nop
; Timer 1 interrupt
	movei	#DSP_LSP_routine_interruption_Timer1,AHX__I2S__tmp_1						; 6 octets
	movei	#D_FLAGS,r30											; 6 octets
	jump	(AHX__I2S__tmp_1)													; 2 octets
	load	(r30),r29	; read flags								; 2 octets = 16 octets
; Timer 2 interrupt	
;	.rept	8
;		nop
;	.endr
; External 0 interrupt
;	.rept	8
;		nop
;	.endr
; External 1 interrupt
;	.rept	8
;		nop
;	.endr


; I2S:
; version sans adaptation du volume, avec SAT
AHX_I2S_N_voies:
	movei		#(NB_channels/2),AHX__I2S__compteur_nb_voie
	movei		#AHX_enregistrements_N_voies,AHX_I2S_pointeur_datas_voie_en_cours_G
	movei		#AHX_enregistrements_N_voies__I2S__taille_totale,AHX_I2S_increment_taille_AHX_enregistrements_N_voies
	move			AHX_I2S_pointeur_datas_voie_en_cours_G,AHX_I2S_pointeur_datas_voie_en_cours_D
	add				AHX_I2S_increment_taille_AHX_enregistrements_N_voies,AHX_I2S_pointeur_datas_voie_en_cours_D
	moveq		#0,AHX__I2S__sample_gauche
	add				AHX_I2S_increment_taille_AHX_enregistrements_N_voies,AHX_I2S_increment_taille_AHX_enregistrements_N_voies
	moveq		#0,AHX__I2S__sample_droite
	movei		#AHX_I2S_N_voies__boucle_voie,AHX__I2S__adresse_code_boucle
	

AHX_I2S_N_voies__boucle_voie:
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G), AHX__I2S__offset_entier_et_virgule__voie_G
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D), AHX__I2S__offset_entier_et_virgule__voie_D	
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__increment), AHX__I2S__increment_entier_et_virgule__voie_G
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__increment), AHX__I2S__increment_entier_et_virgule__voie_D
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__mask_bouclage), AHX__I2S__mask_bouclage_voie_G
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__mask_bouclage), AHX__I2S__mask_bouclage_voie_D	
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__buffer), AHX__I2S__adresse_buffer_sample__voie_G
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__buffer), AHX__I2S__adresse_buffer_sample__voie_D	
		
	add		AHX__I2S__increment_entier_et_virgule__voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
		add		AHX__I2S__increment_entier_et_virgule__voie_D,AHX__I2S__offset_entier_et_virgule__voie_D

	store		AHX__I2S__offset_entier_et_virgule__voie_G,(AHX_I2S_pointeur_datas_voie_en_cours_G)
		store		AHX__I2S__offset_entier_et_virgule__voie_D,(AHX_I2S_pointeur_datas_voie_en_cours_D)

	and		AHX__I2S__mask_bouclage_voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
		and		AHX__I2S__mask_bouclage_voie_D,AHX__I2S__offset_entier_et_virgule__voie_D

	sharq	#AHX_nb_bits_virgule_increment_period-2,AHX__I2S__offset_entier_et_virgule__voie_G			; -2 pour *4
		sharq	#AHX_nb_bits_virgule_increment_period-2,AHX__I2S__offset_entier_et_virgule__voie_D			; -2 pour *4	
		
	add		AHX__I2S__adresse_buffer_sample__voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
		add		AHX__I2S__adresse_buffer_sample__voie_D,AHX__I2S__offset_entier_et_virgule__voie_D

	load	(AHX__I2S__offset_entier_et_virgule__voie_G),AHX__I2S__tmp_sample_G			; lit le sample en .L, prémultiplié par le volume
		load	(AHX__I2S__offset_entier_et_virgule__voie_D),AHX__I2S__tmp_sample_D

; RM à gérer ici
; voie G
; load l'increment et si =0 => pas de RM
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__increment__RM), AHX__I2S__increment_entier_et_virgule__voie_G
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__increment__RM), AHX__I2S__increment_entier_et_virgule__voie_D
	cmpq		#0,AHX__I2S__increment_entier_et_virgule__voie_G
	jr			eq,AHX_I2S_N_voies__pas_de_RM__voie_G
; RM en voie G	
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__offset__RM), AHX__I2S__offset_entier_et_virgule__voie_G
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__buffer__RM), AHX__I2S__adresse_buffer_sample__voie_G
	add			AHX__I2S__increment_entier_et_virgule__voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
	store	AHX__I2S__offset_entier_et_virgule__voie_G,(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__offset__RM)
	and			AHX__I2S__mask_bouclage_voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
	sharq	#AHX_nb_bits_virgule_increment_period-2,AHX__I2S__offset_entier_et_virgule__voie_G			; -2 pour *4
	add			AHX__I2S__adresse_buffer_sample__voie_G,AHX__I2S__offset_entier_et_virgule__voie_G
	load		(AHX__I2S__offset_entier_et_virgule__voie_G),AHX__I2S__increment_entier_et_virgule__voie_G			; lit le sample en .L, du RM
	imult	AHX__I2S__increment_entier_et_virgule__voie_G,AHX__I2S__tmp_sample_G
	sharq	#7,AHX__I2S__tmp_sample_G
AHX_I2S_N_voies__pas_de_RM__voie_G:	
; voie D
; load l'increment et si =0 => pas de RM
	cmpq		#0,AHX__I2S__increment_entier_et_virgule__voie_D
	jr			eq,AHX_I2S_N_voies__pas_de_RM__voie_D
; RM en voie G	
	load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__offset__RM), AHX__I2S__offset_entier_et_virgule__voie_D
	load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__buffer__RM), AHX__I2S__adresse_buffer_sample__voie_D
	add			AHX__I2S__increment_entier_et_virgule__voie_D,AHX__I2S__offset_entier_et_virgule__voie_D
	store	AHX__I2S__offset_entier_et_virgule__voie_D,(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__offset__RM)
	and			AHX__I2S__mask_bouclage_voie_D,AHX__I2S__offset_entier_et_virgule__voie_D
	sharq	#AHX_nb_bits_virgule_increment_period-2,AHX__I2S__offset_entier_et_virgule__voie_D			; -2 pour *4
	add			AHX__I2S__adresse_buffer_sample__voie_D,AHX__I2S__offset_entier_et_virgule__voie_D
	load		(AHX__I2S__offset_entier_et_virgule__voie_D),AHX__I2S__increment_entier_et_virgule__voie_D			; lit le sample en .L, du RM
	imult	AHX__I2S__increment_entier_et_virgule__voie_D,AHX__I2S__tmp_sample_D
	sharq	#7,AHX__I2S__tmp_sample_D
AHX_I2S_N_voies__pas_de_RM__voie_D:	
	
	
	
	


; stereo panning
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__panning_left),AHX__I2S__tmp_1					; voie 1 / panning left
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__panning_left),AHX__I2S__tmp_3					; voie 2 / panning left		
	load		(AHX_I2S_pointeur_datas_voie_en_cours_G+index_AHX_enregistrements_N_voies__I2S__panning_right),AHX__I2S__tmp_2				; voie 1 / panning right
		load		(AHX_I2S_pointeur_datas_voie_en_cours_D+index_AHX_enregistrements_N_voies__I2S__panning_right),AHX__I2S__tmp_4				; voie 2 / panning right

; sample * panning
	imult	AHX__I2S__tmp_sample_G,AHX__I2S__tmp_1
	imult	AHX__I2S__tmp_sample_D,AHX__I2S__tmp_3
	imult	AHX__I2S__tmp_sample_G,AHX__I2S__tmp_2
	imult	AHX__I2S__tmp_sample_D,AHX__I2S__tmp_4	
	sharq		#7,AHX__I2S__tmp_1
	sharq		#7,AHX__I2S__tmp_2
	sharq		#7,AHX__I2S__tmp_3
	sharq		#7,AHX__I2S__tmp_4
	

	add		AHX__I2S__tmp_1,AHX__I2S__sample_gauche
		add		AHX__I2S__tmp_2,AHX__I2S__sample_droite
	add		AHX__I2S__tmp_3,AHX__I2S__sample_gauche
		add		AHX__I2S__tmp_4,AHX__I2S__sample_droite

	add			AHX_I2S_increment_taille_AHX_enregistrements_N_voies,AHX_I2S_pointeur_datas_voie_en_cours_G
	add			AHX_I2S_increment_taille_AHX_enregistrements_N_voies,AHX_I2S_pointeur_datas_voie_en_cours_D
		
	subq	#1,AHX__I2S__compteur_nb_voie
	jump	ne,(AHX__I2S__adresse_code_boucle)
	nop

	;movei		#L_I2S+4,AHX__I2S__increment_entier_et_virgule__voie_G
	sat16s		AHX__I2S__sample_gauche
	;movei		#L_I2S,AHX__I2S__increment_entier_et_virgule__voie_D
	sat16s		AHX__I2S__sample_droite
	store		AHX__I2S__sample_gauche,(AHX_I2S_pointeur_DAC_voie_G)
	store		AHX__I2S__sample_droite,(AHX_I2S_pointeur_DAC_voie_D)				; droite	

; return from interrupt I2S
		load	(r31),AHX__I2S__tmp_1					; return address
		bclr	#3,AHX__I2S__save_flags						; clear IMASK
		bset	#10,AHX__I2S__save_flags						; clear latch 1 = I2S
		addq	#4,r31										; pop from stack
		addqt	#2,AHX__I2S__tmp_1						; next instruction
		jump	(AHX__I2S__tmp_1)						; return
		store	AHX__I2S__save_flags,(R30)		; restore flags
;------------------------------------	



;--------------------------------------------
; Timer 1
DSP_LSP_routine_interruption_Timer1:
; juste flag // A mettre en registre ?
	
	movei		#DSP_flag_replay_ON_OFF,AHX__I2S__tmp_1
	load			(AHX__I2S__tmp_1),AHX__I2S__tmp_2
	cmpq			#2,AHX__I2S__tmp_2
	jr				ne,DSP_LSP_routine_interruption_Timer1__pas_de_sortie
	nop
	moveq		#3,AHX__I2S__tmp_3
	bclr		#6,R29	; clear Timer 1 Interrupt Enable Bit
	store		AHX__I2S__tmp_3,(AHX__I2S__tmp_1)
	

DSP_LSP_routine_interruption_Timer1__pas_de_sortie:	
; return from interrupt Timer 1
	;movei	#D_FLAGS,r11											; 6 octets
	movei		#AHX_DSP_flag_timer1,AHX__I2S__tmp_1
	moveq		#1,AHX__I2S__tmp_2
		load		(r31),AHX__I2S__tmp_3					; return address
	store		AHX__I2S__tmp_2,(AHX__I2S__tmp_1)
		bclr	#3,R29						; clear IMASK
		bset	#11,R29						; clear latch 1 = timer 1
		addq	#4,r31										; pop from stack
		addqt	#2,AHX__I2S__tmp_3						; next instruction
		jump	(AHX__I2S__tmp_3)						; return
		store	R29,(R30)		; restore flags
;------------------------------------	





;------------------------------------------
;------------------------------------------
; ------------- main DSP ------------------
;------------------------------------------
;------------------------------------------



DSP_routine_init_DSP:


; test 
;test_lecture_bits:
;		dc.w				$ABCD
;		dc.w				$1234
;		dc.w				$5678
;		dc.w				0,0,0,0
;;
;;
;;		movei		#test_lecture_bits,R11
;;		movei		#numero_bit_actuel_dans_streaming_bits,R12
;;		load			(R12),R13
;;; test
;;	movei			#test_retour1,R28
;;	movei			#DSP__AHX_decode_streaming_V3__read_bits_from_bits_streaming,R27
;;	moveq			#24,R0		
;;	nop
;;	jump				(R27)
;;	nop
;;test_retour1:
;;		; R1= $ABCD12
;;
;;	movei			#test_retour2,R28
;;	moveq			#16,R0		
;;	nop
;;	jump				(R27)
;;	nop
;;test_retour2:
;;		; R1=3456
;;	
;;	movei			#test_retour3,R28
;;	moveq			#9,R0		
;;	nop
;;	jump				(R27)
;;	nop
;;test_retour3:
		; R1=78<<1=F0
	
; test lecture ram en .w
;		movei				#DSP_memory_W_test_original,R10
;		movei				#DSP_memory_W_test_resultat,R11
;		
;		loadw				(R10),R0					; 1234
;		addq					#2,R10
;		loadw				(R10),R1
;		shlq					#16,R0
;		or						R0,R1
;		store					R1,(R11)
		
	


; assume run from bank 1
	movei	#DSP_ISP+(DSP_STACK_SIZE*4),r31			; init isp
	moveq	#0,r1
	moveta	r31,r31									; ISP (bank 0)
	nop
	movei	#DSP_USP+(DSP_STACK_SIZE*4),r31			; init usp




; calculs des frequences deplacé dans DSP
; sclk I2S
	movei		#JOYBUTS,r0
	loadw		(r0),r3
	btst		#4,r3
	movei	#415530<<8,r1	;frequence_Video_Clock_divisee*128
	jr			eq,initPAL
	nop
	movei	#415483<<8,r1	;frequence_Video_Clock_divisee*128
initPAL:
    movei    #DSP_Audio_frequence,R0
    div     	 R0,R1
	or			R1,R1
    movei 	   #128,R2
    add      	R2,R1		; +128 = +0.5
    shrq     	#8,R1
    subq     	#1,R1
    movei    #DSP_parametre_de_frequence_I2S,r2
    store   	 R1,(R2)
;calcul inverse
    addq    #1,R1
    add     R1,R1		; *2
    add     R1,R1		; *2
    shlq    #4,R1	; *16

	btst	#4,r3
	movei	#26593900,r0	;frequence_Video_Clock
	jr	eq,initPAL2
	nop
	movei	#26590906,r0	;frequence_Video_Clock
initPAL2:
    div      	R1,R0
	or			R0,R0
    movei    #DSP_frequence_de_replay_reelle_I2S,R2
    store    R0,(R2)

; calcul constants ratio Amiga/Jaguar
	movei	#3546895<<9,R1
	movei	#DSP_ratio_Amiga_Jaguar__a_virgule_9_bits,R2
	div		R0,R1
	or		R1,R1
	shlq		#AHX_nb_bits_virgule_increment_period-9,R1		; maxi = 31 bits : 31-15 = 16 - ( 2+5) = 9
	store	R1,(R2)


	; moveta, constantes I2S
;AHX_I2S_pointeur_DAC_voie_G														.equr		R18
;AHX_I2S_pointeur_DAC_voie_D														.equr		R19
	movei		#L_I2S+4,R0
	movei		#L_I2S,R1
	moveta		R0,AHX_I2S_pointeur_DAC_voie_G
	moveta		R1,AHX_I2S_pointeur_DAC_voie_D
	movei		#AHX_I2S_N_voies,R0
	moveta		R0,AHX__I2S__routine_actuelle
	

	
; init I2S
	movei	#SCLK,r10
	movei	#SMODE,r11
	movei	#DSP_parametre_de_frequence_I2S,r12
	movei	#%001101,r13			; SMODE bascule sur RISING
	load	(r12),r12				; SCLK
	store	r12,(r10)
	store	r13,(r11)


; init Timer 1 = 50 HZ

	movei	#HVL_speed_multiplier,R2
	movei	#3643,R13					; valeur pour 50 Hz
	load		(R2),R0							; = plyPSpeed / If SPD=0, the mod plays at 50Hz //  SPD=1, 100Hz. SPD=2, 150Hz. SPD=3, 200Hz
	addq		#1,R0
	div			R0,R13					; divise pour avoir la bonne vitesse de replay
	or			R13,R13
		
	subq		#1,R13					; -1 pour parametrage du timer 1
	
; 26593900 / 50 = 531 878 => 2 × 73 × 3643 => 146*3643
	movei	#JPIT1,r10				; F10000
	;movei	#JPIT2,r11				; F10002
	movei	#145*65536,r12				; Timer 1 Pre-scaler
	;shlq	#16,r12
	or		R13,R12
	store	r12,(r10)				; JPIT1 & JPIT2



; ------------------
; init registres I2S
; ------------------
; init registres I2S
; init des buffers
	movei		#AHX_enregistrements_N_voies,R14
	moveq		#NB_channels,R0
	movei		#buffer_128_1,R1
	movei		#128*4,R2
	movei		#AHX_enregistrements_N_voies__I2S__taille_totale,R3
DSP_boucle_init_pointeurs_buffers:	
	store		R1,(R14+index_AHX_enregistrements_N_voies__I2S__buffer)
	or				R1,R1
	add				R2,R1
	add				R3,R14
	subq			#1,R0
	jr				ne,DSP_boucle_init_pointeurs_buffers
	nop
	

; enable interrupts
	movei	#D_FLAGS,r24
; prod version
;	movei	#D_I2SENA|D_TIM1ENA|D_TIM2ENA|REGPAGE|D_CPUENA,r29			; I2S+Timer 1+timer 2+CPU
	movei	#D_I2SENA|D_TIM1ENA|REGPAGE,r29			; I2S+Timer 1
	;movei	#D_I2SENA|REGPAGE,r29					; I2S only
	;movei	#D_TIM1ENA|REGPAGE,r29					; Timer 1 only
	;movei	#D_TIM2ENA|REGPAGE,r29					; Timer 2 only
			; demarre les timers
	store	r29,(r24)
	nop
	nop


;------------------------------------------------------
;
; boucle centrale
;
;------------------------------------------------------

DSP_boucle_centrale:
	movei		#AHX_DSP_flag_timer1,R22
DSP_boucle_centrale__wait_for_timer1_and_68000tick:
	load		(R22),R21
	cmpq		#1,R21				; attente du timer 1
	jr			ne,DSP_boucle_centrale__wait_for_timer1_and_68000tick
	nop


	movei			#DSP_flag_replay_ON_OFF,R0
	movei			#DSP_sortie_finale,R2
	load				(R0),R1
	cmpq				#0,R1
	jump				ne,(R2)
	nop


; change la couleur de fond - debug
	.if		display_time=1
	movei	#$77,R26
	movei	#BG,r27
	storew	r26,(r27)
	.endif


; incremente frame DSP - debug
	movei		#numero_de_frame_DSP,R12
	load			(R12),R11
	or				R11,R11
	addq			#1,R11
	or				R11,R11
	store		R11,(R12)




; ------------------------------
; decode stream AHX version bits
;HIVELY_datas_channels:
;		.rept		NB_channels
;		dc.l			0									; vc_AudioVolume
;		dc.l			0									; vc_Waveform
;		dc.l			0									; vc_SquarePos
;		dc.l			0									; vc_WaveLength
;		dc.l			0									; vc_FilterPos
;		dc.l			0									; vc_AudioPeriod
;		; Ring Modulation : vc_Waveform+vc_WaveLength+vc_AudioPeriod 
;		.endr


DSP__decode_bits__nb_bits_a_lire														.equr				R0
DSP__decode_bits__bits_resultat														.equr				R1
DSP__decode_bits__tmp0																			.equr				R2
DSP__decode_bits__tmp1																			.equr				R3
DSP__decode_bits__compteur_voies														.equr				R4
DSP__decode_bits__flags_datas															.equr				R5
;DSP__decode_bits__bits_resultat_compose										.equr				R6
DSP__decode_bits__taille_d_un_record_datas_channel			.equr				R7
DSP__decode_bits__tmp2																			.equr				R8
DSP__decode_bits__tmp3																			.equr				R9

DSP__decode_bits__adresse_pointeur_lecture_bits					.equr				R10
DSP__decode_bits__pointeur_lecture_bits										.equr				R11
DSP__decode_bits__adresse_numero_bit_actuel							.equr				R12
DSP__decode_bits__numero_bit_actuel												.equr				R13
DSP__decode_bits__datas_channels_destination							.equr				R14
DSP__decode_bits__datas_I2S_destination										.equr				R15
DSP__decode_bits__table_panning_voies											.equr				R19

DSP__decode_bits__adresse_boucle_lecture_bits						.equr				R20
DSP__decode_bits__adresse_boucle_enreg_datas_channels	.equr				R21
DSP__decode_bits__increment_datas_I2S_destination				.equr				R22
DSP__decode_bits__adresse_routine_lecture_bits					.equr				R27
DSP__decode_bits__adresse_retour														.equr				R28


; 0x00F1B1D4
		movei		#AHX_enregistrements_N_voies,DSP__decode_bits__datas_I2S_destination
		movei		#AHX_enregistrements_N_voies__I2S__taille_totale,DSP__decode_bits__increment_datas_I2S_destination
		movei		#DSP__AHX_decode_streaming_V3__read_bits_from_bits_streaming,DSP__decode_bits__adresse_routine_lecture_bits
		movei		#pointeur_actuel_sur_AHX_streaming_bits,DSP__decode_bits__adresse_pointeur_lecture_bits
		movei		#numero_bit_actuel_dans_streaming_bits,DSP__decode_bits__adresse_numero_bit_actuel
		load			(DSP__decode_bits__adresse_pointeur_lecture_bits),DSP__decode_bits__pointeur_lecture_bits
		load			(DSP__decode_bits__adresse_numero_bit_actuel),DSP__decode_bits__numero_bit_actuel
		
;	tester fin de stream
		movei			#fin_module_AHX_streaming_bits,DSP__decode_bits__tmp0
		cmp				DSP__decode_bits__tmp0,DSP__decode_bits__pointeur_lecture_bits
		jr					cs,DSP_boucle_read_bits_per_channel__pas_fin_du_fichier
		nop
		movei		#module_AHX_streaming_bits,DSP__decode_bits__pointeur_lecture_bits
		moveq		#31,DSP__decode_bits__numero_bit_actuel	
DSP_boucle_read_bits_per_channel__pas_fin_du_fichier:		
		
		
		
		movei		#DSP__AHX_read_bits_from_bits_streaming__boucle,DSP__decode_bits__adresse_boucle_lecture_bits
		;moveq		#DSP_offset_vc__total	,DSP__decode_bits__taille_d_un_record_datas_channel
		;movei		#HIVELY_datas_channels,DSP__decode_bits__datas_channels_destination
		moveq		#NB_channels,DSP__decode_bits__compteur_voies
		movei		#DSP_boucle_read_bits_per_channel,DSP__decode_bits__adresse_boucle_enreg_datas_channels
		movei		#DSP__HVL_table_panning_voies_de_base,DSP__decode_bits__table_panning_voies

DSP_boucle_read_bits_per_channel:
	load				(DSP__decode_bits__table_panning_voies),DSP__decode_bits__datas_channels_destination

; lecture des 7 bits de description/flags
		movei		#DSP_lecture_bits_adresse_retour1,DSP__decode_bits__adresse_retour
		jump			(DSP__decode_bits__adresse_routine_lecture_bits)
		moveq		#8,DSP__decode_bits__nb_bits_a_lire					; lit 7 bits => DSP__decode_bits__bits_resultat

DSP_lecture_bits_adresse_retour1:
		move			DSP__decode_bits__bits_resultat,DSP__decode_bits__flags_datas

;--- 7
; vc_Pan : 8 bits
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_Pan,DSP__decode_bits__tmp0
	btst			#7,DSP__decode_bits__flags_datas
	jump			eq,(DSP__decode_bits__tmp0)
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour0,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#8,DSP__decode_bits__nb_bits_a_lire
	
DSP__AHX_decode_streaming_V2__boucle_voie__retour0:
	nop
	; R01=vc_Pan
; ici , convertir vc pan en ?
	movei		#Hively_panning_left,DSP__decode_bits__tmp0
	movei		#Hively_panning_right,DSP__decode_bits__tmp1
	add				DSP__decode_bits__bits_resultat,DSP__decode_bits__tmp0
	add				DSP__decode_bits__bits_resultat,DSP__decode_bits__tmp1
	loadb		(DSP__decode_bits__tmp0),DSP__decode_bits__tmp0
	loadb		(DSP__decode_bits__tmp1),DSP__decode_bits__tmp1
	or				DSP__decode_bits__tmp0,DSP__decode_bits__tmp0
	or				DSP__decode_bits__tmp1,DSP__decode_bits__tmp1
	store		DSP__decode_bits__tmp0,(DSP__decode_bits__datas_I2S_destination+index_AHX_enregistrements_N_voies__I2S__panning_left)
	store		DSP__decode_bits__tmp1,(DSP__decode_bits__datas_I2S_destination+index_AHX_enregistrements_N_voies__I2S__panning_right)
	
;--- 6
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_Pan:
; vc_AudioVolume : 6 bits
	btst			#6,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_AudioVolume
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour2,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#6,DSP__decode_bits__nb_bits_a_lire
	
DSP__AHX_decode_streaming_V2__boucle_voie__retour2:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_AudioVolume)

;--- 5
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_AudioVolume:
; vc_Waveform : 2 bits
	btst			#5,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_Waveform
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour3,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#2,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour3:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_Waveform)

;--- 4
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_Waveform:
; vc_SquarePos : 6 bits
	btst			#4,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_SquarePos
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour4,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#6,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour4:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_SquarePos)

;--- 3
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_SquarePos:
; vc_WaveLength : 3 bits
	btst			#3,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_WaveLength
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour5,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#3,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour5:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_WaveLength)

;--- 2
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_WaveLength:
; vc_FilterPos : 6 bits
	btst			#2,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_FilterPos
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour6,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#6,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour6:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_FilterPos)

;--- 1
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_FilterPos:
; vc_AudioPeriod : 12 bits 
	btst			#1,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_AudioPeriod
	nop
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour7,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#12,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour7:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_AudioPeriod)

;--- 0
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_vc_AudioPeriod:
; Ring Modulation N/A
	btst			#0,DSP__decode_bits__flags_datas
	jr				eq,DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_RM
	nop
; lecture vc_RingWaveform
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour8,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#1,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour8:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_RingWaveform)
; lecture vc_RingAudioPeriod
	movei		#DSP__AHX_decode_streaming_V2__boucle_voie__retour9,DSP__decode_bits__adresse_retour
	jump			(DSP__decode_bits__adresse_routine_lecture_bits)
	moveq		#12,DSP__decode_bits__nb_bits_a_lire

DSP__AHX_decode_streaming_V2__boucle_voie__retour9:
	store		DSP__decode_bits__bits_resultat,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_RingAudioPeriod)
	
DSP__AHX_decode_streaming_V2__boucle_voie__pas_de_RM:
; check si channel on, si off on met le volume à zéro
	load				(DSP__decode_bits__datas_channels_destination+DSP_index_vc_channel_on_off),DSP__decode_bits__flags_datas
	or					DSP__decode_bits__flags_datas,DSP__decode_bits__flags_datas
	cmpq				#0,DSP__decode_bits__flags_datas
	jr					ne,DSP_read_bits__pas_channel_off
	moveq			#0,DSP__decode_bits__nb_bits_a_lire
	or					DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__nb_bits_a_lire
	store			DSP__decode_bits__nb_bits_a_lire,(DSP__decode_bits__datas_channels_destination+DSP_index_vc_AudioVolume)
DSP_read_bits__pas_channel_off:

	;add					DSP__decode_bits__taille_d_un_record_datas_channel,DSP__decode_bits__datas_channels_destination
	add					DSP__decode_bits__increment_datas_I2S_destination,DSP__decode_bits__datas_I2S_destination
	addq			#4,DSP__decode_bits__table_panning_voies
	subq				#1,DSP__decode_bits__compteur_voies
	jump				ne,(DSP__decode_bits__adresse_boucle_enreg_datas_channels)
	nop

; penser à enregistrer les 2 souces de bits, pointeur et position

;	tester fin de stream
;		movei			#fin_module_AHX_streaming_bits,DSP__decode_bits__tmp0
;		cmp				DSP__decode_bits__tmp0,DSP__decode_bits__pointeur_lecture_bits
;		jr					cs,DSP_boucle_read_bits_per_channel__pas_fin_du_fichier
;		nop
;		movei		#module_AHX_streaming_bits,DSP__decode_bits__pointeur_lecture_bits
;		moveq		#7,DSP__decode_bits__numero_bit_actuel		
;DSP_boucle_read_bits_per_channel__pas_fin_du_fichier:


		store			DSP__decode_bits__pointeur_lecture_bits,(DSP__decode_bits__adresse_pointeur_lecture_bits)
		store			DSP__decode_bits__numero_bit_actuel,(DSP__decode_bits__adresse_numero_bit_actuel)


; FIN DE : decode stream AHX version bits
; ------------------------------




; ------------------------------
; interprete valeurs dans datas pour chaque channels pour remplir increment, mask et buffer
;
; increment en fonction de l'audioperiod
; mask en fonction de wavelength uniquement ?
;
;
; vc_AudioVolume
; vc_Waveform
; vc_SquarePos
; vc_WaveLength
; vc_FilterPos
; vc_AudioPeriod
;

; --------------- code de gestion du AHX vers I2S ------------------------
; triangle et sawtooth : lire N octets ( wavelength) / appliquer le filtre sur N octets/ appliquer le volume sur N octets												: 1 buffer temporaire = buffer_temp_wave
; square : generer 128 octets / apppliquer le filtre sur 128 octets / lire N octets ( wavelength) / appliquer le volume sur N octets					: possible sur 1 buffer temporaire : source et dest meme adresse lors de la selection des octets
; noise : generer 128 octets / apppliquer le filtre sur 128 octets / appliquer le volume sur 128 octets																						: 1 buffer temporaire
;
; 4 routines :
;	- lire wavelength octets d'une source vers une dest
;	- appliquer le filtre sur une source/dest pour N octets
;	- appliquer le volume pour une source/dest sur N octets
;	- square generer 128 octets
;	- noise generer 128 octets


; - si volume=0 => buffer tout à zéro, rapidement, double dest
; il faut remplir volume OK // wavelength en octets OK // décaleur en fonction de wavelength OK // filterpos // increment pour envoi à I2S OK // mask pour bouclage pour envoi à I2S OK

																																																											; reutilisable ?
DSP__genere_wave__tmp0																								.equr					R0																					;-------------
DSP__genere_wave__tmp1																								.equr					R1																					;-------------
DSP__genere_wave__tmp2																								.equr					R2																					;-------------
DSP__genere_wave__tmp3																								.equr					R3																					;-------------
DSP__genere_wave__tmp4																								.equr					R4																					;-------------
DSP__genere_wave__tmp5																								.equr					R5																					;-------------
DSP__genere_wave__ratio_amiga_jaguar																.equr					R6																					;		si necessaire
DSP__genere_wave__wavelength_en_octets															.equr					R7																					;			NON
DSP__genere_wave__increment_pour_lire_les_octets									.equr					R8																					;			NON
DSP__genere_wave__compteur_channels																	.equr					R9																					;			NON
							
DSP__genere_wave__volume																							.equr					R10																					;			NON
DSP__genere_wave__wavelength																					.equr					R11																					;			NON
DSP__genere_wave__decaleur_wavelength																.equr					R12																					;			-OUI-
DSP__genere_wave__filterpos																						.equr					R13																					;			NON
DSP__genere_wave__source_datas_channel															.equr					R14																					;			NON
DSP__genere_wave__dest_record_I2S																		.equr					R15																					;			NON
DSP__genere_wave__audioperiod																				.equr					R16																					;			-OUI-
DSP__genere_wave__mask_pour_I2S																			.equr					R17																					;			NON
DSP__genere_wave__waveform																						.equr					R18																					;			NON
DSP__genere_wave__squarepos																						.equr					R19																					;			NON
							
DSP__genere_wave__increment_pour_I2S																.equr					R20																					;			NON
DSP__genere_wave__routines_a_executer																.equr					R21																					;		si necessaire
DSP__genere_wave__tmp6																								.equr					R22																					;-------------
DSP__genere_wave__tmp7																								.equr					R23																					;-------------
DSP__genere_wave__wavelength_en_octets__pour_filtre								.equr					R24																					;			NON
DSP__genere_wave__tmp9																								.equr					R25																					;-------------
DSP__genere_wave__tmp8																								.equr					R26																					;-------------
DSP__genere_wave__boucle_sur_un_channel															.equr					R27																					;			NON
DSP__genere_wave__routine_volume_a_zero	 														.equr					R28																					;		si necessaire
AHX__main__pointeur_adresse_routine_etape_suivante								.equr					R29																					;			NON
DSP__genere_wave__increment_RM_pour_I2S															.equr					R30																					;			NON




		movei		#AHX_enregistrements_N_voies,DSP__genere_wave__dest_record_I2S
		movei		#HIVELY_datas_channels,DSP__genere_wave__source_datas_channel
		movei		#DSP_ratio_Amiga_Jaguar__a_virgule_9_bits,DSP__genere_wave__ratio_amiga_jaguar
		moveq		#NB_channels,DSP__genere_wave__compteur_channels		
		movei		#DSP_genere_wave_routine_volume_a_zero,DSP__genere_wave__routine_volume_a_zero
		load			(DSP__genere_wave__ratio_amiga_jaguar),DSP__genere_wave__ratio_amiga_jaguar
		movei		#AHX_table_routines_a_executer,DSP__genere_wave__routines_a_executer
		movei			#DSP_genere_wave__boucle,DSP__genere_wave__boucle_sur_un_channel

DSP_genere_wave__boucle:

		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_AudioVolume),DSP__genere_wave__volume
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_Waveform),DSP__genere_wave__waveform
		cmpq			#0,DSP__genere_wave__volume
		jump			eq,(DSP__genere_wave__routine_volume_a_zero)
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_SquarePos),DSP__genere_wave__squarepos
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_WaveLength),DSP__genere_wave__wavelength						; = wavelength : 0 à 5 ( 2^(n+2) ) // $04/$08/$10/$20/$40/$80		0=$04, 1=$08, 2=$10, 3=$20, 4=$40, 5=$80
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_FilterPos),DSP__genere_wave__filterpos
		moveq		#5,DSP__genere_wave__decaleur_wavelength
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_AudioPeriod),DSP__genere_wave__audioperiod
		sub				DSP__genere_wave__wavelength,DSP__genere_wave__decaleur_wavelength
		moveq		#1,DSP__genere_wave__increment_pour_lire_les_octets
		neg				DSP__genere_wave__decaleur_wavelength
		addq			#2,DSP__genere_wave__wavelength			; wavelength + 2
		sh				DSP__genere_wave__decaleur_wavelength,DSP__genere_wave__increment_pour_lire_les_octets
		moveq		#1,DSP__genere_wave__wavelength_en_octets
		neg				DSP__genere_wave__wavelength
		move			DSP__genere_wave__ratio_amiga_jaguar,DSP__genere_wave__increment_pour_I2S
		sh				DSP__genere_wave__wavelength,DSP__genere_wave__wavelength_en_octets
		move			DSP__genere_wave__waveform,DSP__genere_wave__tmp7
		div				DSP__genere_wave__audioperiod,DSP__genere_wave__increment_pour_I2S
		movei			#buffer_temp_wave,DSP__genere_wave__tmp6																				;dest pour triangle et sawtooth, variaiblisé pour gérer le RM
		or				DSP__genere_wave__increment_pour_I2S,DSP__genere_wave__increment_pour_I2S
		shlq			#2,DSP__genere_wave__tmp7				; waveform * 4
		move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__mask_pour_I2S
		movei		#AHX__main__routine__filtre,AHX__main__pointeur_adresse_routine_etape_suivante
		add				DSP__genere_wave__routines_a_executer,DSP__genere_wave__tmp7						; choix de la routine suivant waveform
		subq			#1,DSP__genere_wave__mask_pour_I2S				; mask pour I2S
		load			(DSP__genere_wave__tmp7),DSP__genere_wave__tmp0
		shlq		#AHX_nb_bits_virgule_increment_period,DSP__genere_wave__mask_pour_I2S			; avec virgule		
		jump			(DSP__genere_wave__tmp0)
		nop
AHX__main__adresse_retour_vers_main_suivant_voie:

; gestion de Ring Modulation
		load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_RingAudioPeriod),DSP__genere_wave__increment_RM_pour_I2S
		cmpq			#0,DSP__genere_wave__increment_RM_pour_I2S
		jr				eq,DSP_genere_wave__boucle__apres_RM
		nop
; buffer dans DSP__genere_wave__tmp6	
		load			(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__buffer__RM),DSP__genere_wave__tmp6				; buffer dest = buffer RM
		move			DSP__genere_wave__ratio_amiga_jaguar,DSP__genere_wave__tmp0
			load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_RingWaveform),DSP__genere_wave__tmp1
		div				DSP__genere_wave__increment_RM_pour_I2S,DSP__genere_wave__tmp0
			shlq			#2,DSP__genere_wave__tmp1				; RM waveform * 4
		or				DSP__genere_wave__tmp0,DSP__genere_wave__tmp0
			add				DSP__genere_wave__routines_a_executer,DSP__genere_wave__tmp1						; choix de la routine suivant waveform pour RM : 0 ou 1
		move			DSP__genere_wave__tmp0,DSP__genere_wave__increment_RM_pour_I2S
			load			(DSP__genere_wave__tmp1),DSP__genere_wave__tmp1
		movei		#DSP_genere_wave__boucle__apres_RM,AHX__main__pointeur_adresse_routine_etape_suivante
			jump			(DSP__genere_wave__tmp1)
			nop


DSP_genere_wave__boucle__apres_RM:
		store		DSP__genere_wave__increment_RM_pour_I2S,(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__increment__RM)
		store		DSP__genere_wave__increment_pour_I2S,(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__increment)
		store		DSP__genere_wave__mask_pour_I2S,(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__mask_bouclage)

DSP_genere_wave__boucle_recolle1:
; avancer les 2 pointeurs
; décompter le nb de channels
		movei		#DSP_offset_vc__total,DSP__genere_wave__tmp0
		movei		#AHX_enregistrements_N_voies__I2S__taille_totale,DSP__genere_wave__tmp1
		add				DSP__genere_wave__tmp0,DSP__genere_wave__source_datas_channel
		add				DSP__genere_wave__tmp1,DSP__genere_wave__dest_record_I2S
		
		subq			#1,DSP__genere_wave__compteur_channels
		jump			ne,(DSP__genere_wave__boucle_sur_un_channel)
		nop
		















;--------------------------------------------------------------------------------------
; change la couleur de fond - debug
	.if		display_time=1
	movei	#$00,R26
	movei	#BG,r27
	storew	r26,(r27)
	.endif


	
; ------------------------------
; retour boucle principale
; bouclage final
	movei	#AHX_DSP_flag_timer1,R2
	moveq	#3,R3
	movei	#DSP_boucle_centrale,R26
	jump	(R26)
	store	R3,(R2)


; sortie finale, extinction du DSP
DSP_sortie_finale:
; R0=DSP_flag_replay_ON_OFF

	movei			#DSP_AHX_routine_interruption_I2S__shutdown_now__real_shutdown,R3
	moveta			R3,AHX__I2S__routine_actuelle

DSP_sortie_finale__wait_for_timer1:
	load			(R0),R1
	cmpq			#3,R1
	jr				ne,DSP_sortie_finale__wait_for_timer1
	moveq		#4,R2

	nop
	movei		#D_CTRL,R20
	moveq		#0,R6
	store		R6,(R0)				; DSP_FLAG_STOP_DSP=0
	nop
	nop
.wait:
	jr				.wait
	store		R6,(R20)



DSP_AHX_routine_interruption_I2S__shutdown_now__real_shutdown:
		movei		#DSP_flag_replay_ON_OFF,AHX__I2S__tmp_3
		moveq		#2,AHX__I2S__tmp_2
		store		AHX__I2S__tmp_2,(AHX__I2S__tmp_3)					; ask timer 1 to stop = 2
; return from interrupt I2S
		load	(r31),AHX__I2S__tmp_1					; return address
	bclr		#5,AHX__I2S__save_flags		; clear I2S enabled = I2S Interrupt Enable Bit : stop I2S
		bclr	#3,AHX__I2S__save_flags						; clear IMASK
		bset	#10,AHX__I2S__save_flags						; clear latch 1 = I2S
		addq	#4,r31										; pop from stack
		addqt	#2,AHX__I2S__tmp_1						; next instruction
		jump	(AHX__I2S__tmp_1)						; return
		store	AHX__I2S__save_flags,(R30)		; restore flags




;--------------------------------------------------------------------------------------
;
;
; subroutines de remplissage des buffers
;
;
;--------------------------------------------------------------------------------------

; ----------------
; triangle = 0x00F1B342
; genere triangle dans buffer_temp_wave // execute AHX__main__routine__filtre // execute AHX__main__routine__volume // puis saute à AHX__main__adresse_retour_vers_main_suivant_voie
AHX_DSP_remplissage_buffer_triangle:
; 3 boucles
	move				DSP__genere_wave__increment_pour_lire_les_octets,DSP__genere_wave__tmp1
	move				DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__tmp2
	shlq				#2,DSP__genere_wave__tmp1			; *4
	sharq			#1,DSP__genere_wave__tmp2			; /2
	;movei			#buffer_temp_wave,DSP__genere_wave__tmp6
	move				DSP__genere_wave__tmp2,DSP__genere_wave__tmp3			; R3 = compteur boucle 2
	moveq			#0,DSP__genere_wave__tmp5
	sharq			#1,DSP__genere_wave__tmp2			; R2 = compteur boucle 1
	movei			#127,DSP__genere_wave__tmp7
	move				DSP__genere_wave__tmp2,DSP__genere_wave__tmp4			; R4 = compteur boucle 3
	
; boucle 1 : +4 par etape
AHX_DSP_remplissage_buffer_triangle__boucle1:
	store			DSP__genere_wave__tmp5,(DSP__genere_wave__tmp6)
	add					DSP__genere_wave__tmp1,DSP__genere_wave__tmp5
	subq				#1,DSP__genere_wave__tmp2
	jr					ne,AHX_DSP_remplissage_buffer_triangle__boucle1
	addqt			#4,DSP__genere_wave__tmp6
	
; boucle 2
AHX_DSP_remplissage_buffer_triangle__boucle2:
	cmp				DSP__genere_wave__tmp7,DSP__genere_wave__tmp5
	jr					mi,AHX_DSP_remplissage_buffer_triangle__boucle2__test80
	nop
	store			DSP__genere_wave__tmp7,(DSP__genere_wave__tmp6)
	jr					AHX_DSP_remplissage_buffer_triangle__boucle2__test80__recolle
	nop
AHX_DSP_remplissage_buffer_triangle__boucle2__test80:
	store			DSP__genere_wave__tmp5,(DSP__genere_wave__tmp6)
AHX_DSP_remplissage_buffer_triangle__boucle2__test80__recolle:
	sub					DSP__genere_wave__tmp1,DSP__genere_wave__tmp5
	subq				#1,DSP__genere_wave__tmp3
	jr					ne,AHX_DSP_remplissage_buffer_triangle__boucle2
	addqt			#4,DSP__genere_wave__tmp6

; boucle 3
AHX_DSP_remplissage_buffer_triangle__boucle3:
	store			DSP__genere_wave__tmp5,(DSP__genere_wave__tmp6)
	add					DSP__genere_wave__tmp1,DSP__genere_wave__tmp5
	subq				#1,DSP__genere_wave__tmp4
	jr					ne,AHX_DSP_remplissage_buffer_triangle__boucle3
	addqt			#4,DSP__genere_wave__tmp6
	
	move				AHX__main__pointeur_adresse_routine_etape_suivante,DSP__genere_wave__tmp1
	move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__wavelength_en_octets__pour_filtre
	movei		#AHX__main__routine__volume,AHX__main__pointeur_adresse_routine_etape_suivante
	;movei		#AHX__main__routine__filtre,DSP__genere_wave__tmp1
	;movei		#AHX__main__adresse_retour_vers_main_suivant_voie,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	;move			AHX__main__pointeur_adresse_routine_etape_suivante_plus_1,AHX__main__pointeur_adresse_routine_etape_suivante_plus_2
	jump			(DSP__genere_wave__tmp1)
	nop

; ----------------
; sawtooth = 0x00F1B39A
AHX_DSP_remplissage_buffer_sawtooth:
; genere sawtooth dans buffer_temp_wave // execute AHX__main__routine__filtre // execute AHX__main__routine__volume // puis saute à AHX__main__adresse_retour_vers_main_suivant_voie
	;movei		#AHX_sample_sawtooth80,AHX__main__source_des_samples

; increment = AHX__main__increment_pour_lire_les_octets
	move			DSP__genere_wave__increment_pour_lire_les_octets,DSP__genere_wave__tmp1
	movei		#$FFFFFF80,DSP__genere_wave__tmp2
	add				DSP__genere_wave__tmp1,DSP__genere_wave__tmp1			; +2 par étape 
	;movei		#buffer_temp_wave,DSP__genere_wave__tmp6
	move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__tmp4

AHX_DSP_remplissage_buffer_sawtooth__generation_et_selection:
	store		DSP__genere_wave__tmp2,(DSP__genere_wave__tmp6)
	add				DSP__genere_wave__tmp1,DSP__genere_wave__tmp2
	subq			#1,DSP__genere_wave__tmp4
	jr				ne,AHX_DSP_remplissage_buffer_sawtooth__generation_et_selection
	addqt		#4,DSP__genere_wave__tmp6
	
	move				AHX__main__pointeur_adresse_routine_etape_suivante,DSP__genere_wave__tmp1
	move				DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__wavelength_en_octets__pour_filtre
	movei			#AHX__main__routine__volume,AHX__main__pointeur_adresse_routine_etape_suivante
	;movei			#AHX__main__routine__filtre,DSP__genere_wave__tmp1
	;movei			#AHX__main__adresse_retour_vers_main_suivant_voie,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	;move				AHX__main__pointeur_adresse_routine_etape_suivante_plus_1,AHX__main__pointeur_adresse_routine_etape_suivante_plus_2
	jump				(DSP__genere_wave__tmp1)
	nop


; ----------------
; square = 0x00F1B3C8
; square : generer 128 octets square / apppliquer le filtre / lire N octets ( wavelength) (suivante) / appliquer le volume (+1) // retour (+2)
; genere 128 octets de square
AHX_DSP_remplissage_buffer_square:
	;movei		#pvt_squarePos,DSP__genere_wave__tmp1
	movei		#128,DSP__genere_wave__wavelength_en_octets__pour_filtre
	;add			AHX__main__pointeur_sur_enregistrement_voice,DSP__genere_wave__tmp1
	movei		#32,DSP__genere_wave__tmp3
	;loadb		(DSP__genere_wave__tmp1),R0				; squarepos = 1 a 64
	move		DSP__genere_wave__wavelength_en_octets__pour_filtre,DSP__genere_wave__tmp5

; relatif a wavelength 
	sh			DSP__genere_wave__decaleur_wavelength,DSP__genere_wave__squarepos				; R19 = -(5-wavelength) // R0 = squarepos

; 32-(abs(position-32)) -1			: de 0 a 31
	subq		#32,DSP__genere_wave__squarepos
	movei		#buffer_temp_wave,DSP__genere_wave__tmp1				; buffer dest 1
	abs			DSP__genere_wave__squarepos
	move		DSP__genere_wave__tmp1,DSP__genere_wave__tmp4
	sub			DSP__genere_wave__squarepos,DSP__genere_wave__tmp3
	movei		#126,DSP__genere_wave__tmp2
	subq		#1,DSP__genere_wave__tmp3					; = 0..31
	btst		#31,DSP__genere_wave__tmp3
	jr			eq,.ok_positif_ou_zero
	;cmpq		#0,DSP__genere_wave__tmp3
	;jr			hi,.ok_positif_ou_zero
	nop
	moveq	#0,DSP__genere_wave__tmp3
.ok_positif_ou_zero:	
	move		DSP__genere_wave__tmp3,DSP__genere_wave__squarepos
	
; 0 : 126*-128//2*127
; 1 : 124*-128//4*127
; 31 : 64*-128//64*127
; nb -128 = 126-(2*nb) = R12
; nb 127 = 128 - (nb de 128) = R14

; compteur initial = -126 a -64
	add			DSP__genere_wave__tmp3,DSP__genere_wave__tmp3			; * 2
	movei		#-128,DSP__genere_wave__tmp6
	sub			DSP__genere_wave__tmp3,DSP__genere_wave__tmp2			; 126-(2* [0..31] ) : 126 à 64
		addqt	#4,DSP__genere_wave__tmp4			; 2eme buffer = +4
	sub			DSP__genere_wave__tmp2,DSP__genere_wave__tmp5
	move		DSP__genere_wave__tmp6,DSP__genere_wave__tmp7

AHX_DSP_remplissage_buffer_square__boucle_moins_128:
	store		DSP__genere_wave__tmp6,(DSP__genere_wave__tmp1)
	store		DSP__genere_wave__tmp7,(DSP__genere_wave__tmp4)
	addq		#8,DSP__genere_wave__tmp1
	subq		#2,DSP__genere_wave__tmp2
	jr			ne,AHX_DSP_remplissage_buffer_square__boucle_moins_128
	addqt		#8,DSP__genere_wave__tmp4

	not			DSP__genere_wave__tmp6					; movei		#127,R6
	not			DSP__genere_wave__tmp7					; move		R6,R7

AHX_DSP_remplissage_buffer_square__boucle_plus_127:
	store		DSP__genere_wave__tmp6,(DSP__genere_wave__tmp1)
	store		DSP__genere_wave__tmp7,(DSP__genere_wave__tmp4)
	addq		#8,DSP__genere_wave__tmp1
	subq		#2,DSP__genere_wave__tmp5
	jr			ne,AHX_DSP_remplissage_buffer_square__boucle_plus_127
	addqt		#8,DSP__genere_wave__tmp4
	
; saut au filtre
	;movei		#buffer_temp_wave,AHX__main__source_des_samples
	movei		#AHX__main__routine__lire_N_octets,AHX__main__pointeur_adresse_routine_etape_suivante
	movei		#AHX__main__routine__filtre,DSP__genere_wave__tmp1
	move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__wavelength_en_octets__pour_filtre	
	;movei		#AHX__main__routine__volume,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	;movei		#AHX__main__adresse_retour_vers_main_suivant_voie,AHX__main__pointeur_adresse_routine_etape_suivante_plus_2
	jump			(DSP__genere_wave__tmp1)
	nop

	
	
	; ----------------
; noise = 0x00F1B436
AHX_DSP_remplissage_buffer_noise:

; noise : generer 128 octets noise / apppliquer le filtre  / appliquer le volume (suivante) // retour (+1)
	movei		#128,DSP__genere_wave__wavelength_en_octets
	movei		#(($80-1)<<AHX_nb_bits_virgule_increment_period),DSP__genere_wave__mask_pour_I2S				; force le mask en accord avec le nb d'octets
	movei		#buffer_temp_wave,DSP__genere_wave__tmp9
	movei		#AHX_DSP_Seed_Noise,DSP__genere_wave__tmp2
	move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__tmp4
	movei		#%10011010,DSP__genere_wave__tmp7
	load			(DSP__genere_wave__tmp2),DSP__genere_wave__tmp3					; R3 = current seed
	movei		#$7F,DSP__genere_wave__tmp0
	move			DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__wavelength_en_octets__pour_filtre			; =128
	movei		#$FFFF,DSP__genere_wave__tmp6
	movei		#$FFFFFF80,DSP__genere_wave__tmp8
	movei		#AHX_DSP_remplissage_buffer_noise__boucle,DSP__genere_wave__tmp2

AHX_DSP_remplissage_buffer_noise__boucle:	
; R0/R1/R2/R3/R4/R5/R6/R7/R8/R9/R10
		btst		#8,DSP__genere_wave__tmp3
		jr			eq,AHX_routine_Main_noise__lower
		nop
		btst		#15,DSP__genere_wave__tmp3
		jr			ne,AHX_routine_Main_noise__mi
		nop
		move		DSP__genere_wave__tmp0,DSP__genere_wave__tmp5					; R0=$7F
		jr			AHX_routine_Main_noise__weida
		nop
AHX_routine_Main_noise__mi:
		move		DSP__genere_wave__tmp8,DSP__genere_wave__tmp5					; = -128
		jr			AHX_routine_Main_noise__weida
		nop
AHX_routine_Main_noise__lower:
		move		DSP__genere_wave__tmp3,DSP__genere_wave__tmp5
		shlq		#24,DSP__genere_wave__tmp5
		sharq		#24,DSP__genere_wave__tmp5				; R5 reste signé, sur 8 bits
AHX_routine_Main_noise__weida:
		rorq		#5,DSP__genere_wave__tmp3	
			; 	ror.l		#5,d0
		xor			DSP__genere_wave__tmp7,DSP__genere_wave__tmp3				; eor.b		#%10011010,d0
			store		DSP__genere_wave__tmp5,(DSP__genere_wave__tmp9)
		move		DSP__genere_wave__tmp3,DSP__genere_wave__tmp1				; move.w		d0,d1
			addq		#4,DSP__genere_wave__tmp9
		rorq		#32-2,DSP__genere_wave__tmp3			; rol.l		#2,d0
		and			DSP__genere_wave__tmp6,DSP__genere_wave__tmp1
		add			DSP__genere_wave__tmp3,DSP__genere_wave__tmp1				; .W = ???? add.w		d0,d1
		and			DSP__genere_wave__tmp6,DSP__genere_wave__tmp1
		xor			DSP__genere_wave__tmp1,DSP__genere_wave__tmp3				; eor.w		d1,d0
		rorq		#3,DSP__genere_wave__tmp3				; ror.l		#3,d0

		subq		#1,DSP__genere_wave__tmp4
		jump		ne,(DSP__genere_wave__tmp2)
		nop

	movei		#AHX_DSP_Seed_Noise,DSP__genere_wave__tmp2
	movei		#AHX__main__routine__filtre,DSP__genere_wave__tmp0				; etape suivante apres noise => filtre
	movei		#AHX__main__routine__volume,AHX__main__pointeur_adresse_routine_etape_suivante
	;move		AHX__main__adresse_retour_vers_main_suivant_voie,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	;move		AHX__main__adresse_retour_vers_main_suivant_voie,AHX__main__pointeur_adresse_routine_etape_suivante_plus_2			; par sécurité
	jump		(DSP__genere_wave__tmp0)
	store		DSP__genere_wave__tmp3,(DSP__genere_wave__tmp2)				; stocke le seed modifié	


	
	
	
; ----------------
AHX__main__routine__filtre:
; appliquer le filtre de dest sur dest
	; tester si filterpos = 32 ?
	; filterpos de 1 a 31 / 32 / 33 a 63 : 1 a 63 : si on fait -32 : de -31 a -1 / 0 / 1 a 31    // AND $1F : -1 and 31=1 / -30 => 2 / 0 / 1 a 31
	; OK calculer freq = 25 + ( 9 * filterpos )
	; calculer position de low dans binPrecalcTable
	; lire mid et low
	; sur AHX__main__wavelength_en_octets__pour_filtre octets

;reg__AHX_filter__filterpos										.equr		R0				; OK
reg__AHX_filter__filterpos_and_1F						.equr		R1				; OK
reg__AHX_filter__32														.equr		R2				; OK
reg__AHX_filter__source_low										.equr		R3				; OK
; double volontaire
reg__AHX_filter__R21														.equr		R3				; OK
reg__AHX_filter__source_mid										.equr		R4				; OK
																																			
reg__AHX_filter__R5														.equr		R5				; OK
reg__AHX_filter__R6														.equr		R22				; OK
reg__AHX_filter__R7														.equr		R23				; OK
reg__AHX_filter__R14														.equr		R30				; OK
reg__AHX_filter__R20														.equr		R12				; OK
reg__AHX_filter__freq													.equr		R16				; OK

AHX__main__filtre_in														.equr		R1				; OK
AHX__main__filtre_high												.equr		R2				; OK
AHX__main__filtre_fre													.equr		R5				; OK
AHX__main__filtre_mid													.equr		R26				; OK
AHX__main__filtre_low													.equr		R25				; OK


;   remplacer R8 et R9 et R16


; relit :	
;			- pvt_filterPos				R13
;			- pvt_Waveform				R18
;			- pvt_Wavelength			R11
;			- 


	load			(DSP__genere_wave__source_datas_channel+DSP_index_vc_WaveLength),DSP__genere_wave__wavelength						; = wavelength : 0 à 5 ( 2^(n+2) ) // $04/$08/$10/$20/$40/$80		0=$04, 1=$08, 2=$10, 3=$20, 4=$40, 5=$80
	;movei		#pvt_filterPos,reg__AHX_filter__R5				; $4C
	moveq		#31,reg__AHX_filter__32
	;add			AHX__main__pointeur_sur_enregistrement_voice,reg__AHX_filter__R5
	move		reg__AHX_filter__32,reg__AHX_filter__filterpos_and_1F
	;loadb		(reg__AHX_filter__R5),reg__AHX_filter__filterpos								; 1 a 63
	addq		#1,reg__AHX_filter__32
	movei		#AHX__main__routine__filtre__no_filter,reg__AHX_filter__source_low
	sub			reg__AHX_filter__32,DSP__genere_wave__filterpos
	jump		eq,(reg__AHX_filter__source_low)
	nop
; il y a un filtre
	and			DSP__genere_wave__filterpos,reg__AHX_filter__filterpos_and_1F			; filterpos & $1F : 1 a 31
	movei		#binPrecalcTable,reg__AHX_filter__source_low
	subq		#1,reg__AHX_filter__filterpos_and_1F										; filterpos : 0 a 30
	movei		#(45*2),reg__AHX_filter__R5
	movei		#((31*(6+6+$20+1))*2),reg__AHX_filter__source_mid
	move		reg__AHX_filter__filterpos_and_1F,reg__AHX_filter__R6
	moveq		#9,reg__AHX_filter__freq
	mult			reg__AHX_filter__R5,reg__AHX_filter__R6											; R6 = filterpos ( 0 a 30) * 45
	mult		reg__AHX_filter__filterpos_and_1F,reg__AHX_filter__freq			; freq = filterpos * 9
	add			reg__AHX_filter__R6,reg__AHX_filter__source_low
	addq		#25,reg__AHX_filter__freq					; freq = 25+(9*filterpos)
	;movei		#pvt_Waveform,reg__AHX_filter__R5
	movei		#AHX_DSP_remplissage_buffer_filter__calcul_filtre,reg__AHX_filter__R20
	;add			AHX__main__pointeur_sur_enregistrement_voice,reg__AHX_filter__R5
	
	;loadb		(reg__AHX_filter__R5),reg__AHX_filter__R6				; R6 = Waveform
	move			DSP__genere_wave__waveform,reg__AHX_filter__R6
	; tester pvt_Waveform
	; 0=triangle / 1=sawtooth / 2=square / 3=noise
	; si = 0 : + pvt_Wavelength*2
	; si = 1 : + (6*2) + pvt_Wavelength*2
	; si = 2 : + (6*2)*2 + pvt_squarePos mais ramené à : 0 à 31 = R18
	; si = 3 : + (6+6+$20)*2

	cmpq		#1,reg__AHX_filter__R6
	jr			hi,AHX_DSP_remplissage_buffer_filter__pas_triangle_ni_sawtooth
	nop
; triangle ou sawtooth
		;movei		#pvt_Wavelength,reg__AHX_filter__R5
		;add			AHX__main__pointeur_sur_enregistrement_voice,reg__AHX_filter__R5
		;loadb		(reg__AHX_filter__R5),reg__AHX_filter__R7
		move		DSP__genere_wave__wavelength,reg__AHX_filter__R7
		add			reg__AHX_filter__R7,reg__AHX_filter__R7								; wavelength*2
		add			reg__AHX_filter__R7,reg__AHX_filter__source_low			; source low OK
		cmpq		#0,reg__AHX_filter__R6
		jump		eq,(reg__AHX_filter__R20)			; 0=triangle
		nop
; sawtooth : + (6*2) + pvt_Wavelength*2
		jump		(reg__AHX_filter__R20)			
		addqt		#(6*2),reg__AHX_filter__source_low

AHX_DSP_remplissage_buffer_filter__pas_triangle_ni_sawtooth:
; square ou noise
		cmpq		#3,reg__AHX_filter__R6
		jr			ne,AHX_DSP_remplissage_buffer_filter__square
		nop
; noise : 45*(filterpos-1)+					(6+6+$20)*2
		movei		#((6+6+$20)*2),reg__AHX_filter__R5
		jump		(reg__AHX_filter__R20)			
		add			reg__AHX_filter__R5,reg__AHX_filter__source_low

AHX_DSP_remplissage_buffer_filter__square:
; noise : + (6*2)*2 + pvt_squarePos mais ramené à : 0 à 31 = R18

		add			DSP__genere_wave__squarepos,DSP__genere_wave__squarepos			; * 2 pour .word
		addq		#((6*2)*2),reg__AHX_filter__source_low
		add			DSP__genere_wave__squarepos,reg__AHX_filter__source_low
	
AHX_DSP_remplissage_buffer_filter__calcul_filtre:
	add			reg__AHX_filter__source_low,reg__AHX_filter__source_mid
	
	

; mid and low sources are reversed	
	loadw		(reg__AHX_filter__source_low),AHX__main__filtre_mid
	movei		#$FF800000,reg__AHX_filter__R6
	loadw		(reg__AHX_filter__source_mid),AHX__main__filtre_low
	movei		#$007F0000,reg__AHX_filter__R7
	shlq		#16,AHX__main__filtre_low
	shlq		#16,AHX__main__filtre_mid
	movei		#AHX__main__routine__filtre__boucle_calcul_filtre,reg__AHX_filter__R20
	sharq		#8,AHX__main__filtre_low
	movei		#buffer_temp_wave,reg__AHX_filter__R14
	sharq		#8,AHX__main__filtre_mid			; ext.l + asl.l #8


;----------- boucle ------------
AHX__main__routine__filtre__boucle_calcul_filtre:
	load		(reg__AHX_filter__R14),AHX__main__filtre_in		; valeur sur 8 bits signée
	shlq		#24,AHX__main__filtre_in
	sharq		#8,AHX__main__filtre_in						; 32 bits signée << 16
	
	move		AHX__main__filtre_in,AHX__main__filtre_high
	sub			AHX__main__filtre_mid,AHX__main__filtre_high
	sub			AHX__main__filtre_low,AHX__main__filtre_high
; clipper 	AHX__main__filtre_high entre $FF80 et $007F
	cmp			reg__AHX_filter__R6,AHX__main__filtre_high
	jr			pl,AHX__main__routine__filtre__high__superieur_au_minimum
	nop
	move		reg__AHX_filter__R6,AHX__main__filtre_high
AHX__main__routine__filtre__high__superieur_au_minimum:
	cmp			reg__AHX_filter__R7,AHX__main__filtre_high
	jr			mi,AHX__main__routine__filtre__high__inferieur_au_maximum
	nop
	move		reg__AHX_filter__R7,AHX__main__filtre_high
AHX__main__routine__filtre__high__inferieur_au_maximum:

; fre  = (high >> 8) * freq;
	move		AHX__main__filtre_high,AHX__main__filtre_fre
	sharq		#8,AHX__main__filtre_fre
	imult		reg__AHX_filter__freq,AHX__main__filtre_fre

; mid = mid + fre
	add			AHX__main__filtre_fre,AHX__main__filtre_mid
	
; clipper 	AHX__main__filtre_mid entre $FF80 et $007F
	cmp			reg__AHX_filter__R6,AHX__main__filtre_mid
	jr			pl,AHX__main__routine__filtre__mid__superieur_au_minimum
	nop
	move		reg__AHX_filter__R6,AHX__main__filtre_mid
AHX__main__routine__filtre__mid__superieur_au_minimum:
	cmp			reg__AHX_filter__R7,AHX__main__filtre_mid
	jr			mi,AHX__main__routine__filtre__mid__inferieur_au_maximum
	nop
	move		reg__AHX_filter__R7,AHX__main__filtre_mid
AHX__main__routine__filtre__mid__inferieur_au_maximum:

; fre  = (mid  >> 8) * freq;	
	move		AHX__main__filtre_mid,AHX__main__filtre_fre
	sharq		#8,AHX__main__filtre_fre
	imult		reg__AHX_filter__freq,AHX__main__filtre_fre

; low = low + fre
	add			AHX__main__filtre_fre,AHX__main__filtre_low

; clipper 	AHX__main__filtre_low entre $FF80 et $007F
	cmp			reg__AHX_filter__R6,AHX__main__filtre_low
	jr			pl,AHX__main__routine__filtre__low__superieur_au_minimum
	nop
	move		reg__AHX_filter__R6,AHX__main__filtre_low
AHX__main__routine__filtre__low__superieur_au_minimum:
	cmp			reg__AHX_filter__R7,AHX__main__filtre_low
	jr			mi,AHX__main__routine__filtre__low__inferieur_au_maximum
	nop
	move		reg__AHX_filter__R7,AHX__main__filtre_low
AHX__main__routine__filtre__low__inferieur_au_maximum:

; choisis si on met low ou high en fonction de filterpos

	cmpq		#0,DSP__genere_wave__filterpos
	jr			pl,AHX__main__routine__filtre__store_high
	nop
; filterpos negatif : store low
	move		AHX__main__filtre_low,reg__AHX_filter__R21
	jr			AHX__main__routine__filtre__store_done
	nop
; store high
AHX__main__routine__filtre__store_high:
	move		AHX__main__filtre_high,reg__AHX_filter__R21

AHX__main__routine__filtre__store_done:
	sharq		#16,reg__AHX_filter__R21
	store		reg__AHX_filter__R21,(reg__AHX_filter__R14)
	
	subq		#1,DSP__genere_wave__wavelength_en_octets__pour_filtre
	jump		ne,(reg__AHX_filter__R20)
	addqt		#4,reg__AHX_filter__R14
	
	


; sortie ou pas de filtre
AHX__main__routine__filtre__no_filter:
	move		AHX__main__pointeur_adresse_routine_etape_suivante,DSP__genere_wave__tmp0
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_1,AHX__main__pointeur_adresse_routine_etape_suivante
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_2,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	jump		(DSP__genere_wave__tmp0)
	nop



	
	
	
	
	
	
	



; ----------------
AHX__main__routine__lire_N_octets:
; dispo : DSP__genere_wave__tmp0
; dispo : DSP__genere_wave__tmp4
; dispo : DSP__genere_wave__tmp7

; lire  AHX__main__wavelength_en_octets octets // increment entre les octets = AHX__main__increment_pour_lire_les_octets // source = AHX__main__source_des_samples // dest = AHX__main__buffer_dest_des_samples
; saut en AHX__main__pointeur_adresse_routine_etape_2 à la fin
	movei	#buffer_temp_wave,DSP__genere_wave__tmp1
	move		DSP__genere_wave__increment_pour_lire_les_octets,DSP__genere_wave__tmp6
	move		DSP__genere_wave__tmp1,DSP__genere_wave__tmp2
	move		DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__tmp5
	shlq		#2,DSP__genere_wave__tmp6				; ecart entre les octets * 4 


	
AHX__main__routine__lire_N_octets__boucle:	
	load		(DSP__genere_wave__tmp1),DSP__genere_wave__tmp3
	;or			DSP__genere_wave__tmp3,DSP__genere_wave__tmp3
	store		DSP__genere_wave__tmp3,(DSP__genere_wave__tmp2)
	add			DSP__genere_wave__tmp6,DSP__genere_wave__tmp1
	subq		#1,DSP__genere_wave__tmp5
	jr			ne,AHX__main__routine__lire_N_octets__boucle
	addqt		#4,DSP__genere_wave__tmp2

; forcement volume juste après
	;movei	#AHX__main__routine__volume,DSP__genere_wave__tmp1
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_1,AHX__main__pointeur_adresse_routine_etape_suivante
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_2,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	;jump		(DSP__genere_wave__tmp1)
	;nop
; ----------------
AHX__main__routine__volume:
; appliquer le volume de dest sur dest // AHX__main__wavelength_en_octets
	movei	#buffer_temp_wave,DSP__genere_wave__tmp1
	move		DSP__genere_wave__wavelength_en_octets,DSP__genere_wave__tmp8
	move		DSP__genere_wave__volume,DSP__genere_wave__tmp0
	load		(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__buffer),DSP__genere_wave__tmp5
	move		DSP__genere_wave__tmp1,DSP__genere_wave__tmp2
	move		DSP__genere_wave__tmp5,DSP__genere_wave__tmp6
	addq		#4,DSP__genere_wave__tmp2
	addq		#4,DSP__genere_wave__tmp6

AHX__main__routine__volume__boucle:
	load			(DSP__genere_wave__tmp1),DSP__genere_wave__tmp3
	load			(DSP__genere_wave__tmp2),DSP__genere_wave__tmp4
	imult		DSP__genere_wave__volume,DSP__genere_wave__tmp3
	imult		DSP__genere_wave__tmp0,DSP__genere_wave__tmp4
	store		DSP__genere_wave__tmp3,(DSP__genere_wave__tmp5)
	store		DSP__genere_wave__tmp4,(DSP__genere_wave__tmp6)
	addq			#8,DSP__genere_wave__tmp1
	addq			#8,DSP__genere_wave__tmp2
	subq		#2,DSP__genere_wave__tmp8
	addqt		#8,DSP__genere_wave__tmp5
	jr			ne,AHX__main__routine__volume__boucle
	addqt		#8,DSP__genere_wave__tmp6

	movei		#AHX__main__adresse_retour_vers_main_suivant_voie,DSP__genere_wave__tmp0
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_1,AHX__main__pointeur_adresse_routine_etape_suivante
	;move		AHX__main__pointeur_adresse_routine_etape_suivante_plus_2,AHX__main__pointeur_adresse_routine_etape_suivante_plus_1
	jump			(DSP__genere_wave__tmp0)
	nop








;--------------- subroutine -----------------
; le volume est à zéro il faut remplir avec des 0 tout le buffer
DSP_genere_wave_routine_volume_a_zero:
	load					(DSP__genere_wave__dest_record_I2S+index_AHX_enregistrements_N_voies__I2S__buffer),DSP__genere_wave__volume
	moveq				#0,DSP__genere_wave__wavelength
	move					DSP__genere_wave__volume,DSP__genere_wave__filterpos
	moveq				#0,DSP__genere_wave__decaleur_wavelength
	movei				#128/2,DSP__genere_wave__squarepos
	addq					#4,DSP__genere_wave__filterpos
DSP_genere_wave_routine_volume_a_zero__boucle:
	store				DSP__genere_wave__wavelength,(DSP__genere_wave__volume)
	store				DSP__genere_wave__decaleur_wavelength,(DSP__genere_wave__filterpos)
	addq					#8,DSP__genere_wave__volume
	subq					#1,DSP__genere_wave__squarepos
	jr						ne,DSP_genere_wave_routine_volume_a_zero__boucle
	addqt				#8,DSP__genere_wave__filterpos
	
; fais la boucle sur le channel
	movei			#DSP_genere_wave__boucle_recolle1,DSP__genere_wave__volume
	jump				(DSP__genere_wave__volume)
	nop
	

;--------------- subroutine -----------------
; lit des bits du stream au DSP / de 1 a 8 bits
; entree : R0=nb bits // R28=adresse de retour
; sortie : R0=octet
; utilise : R10/R11/R12/R13/R14/  /R17/R18/R19

; V3, lecture sur 32 bis
;--
; adresse actuelle, multiple de 4
; position actuelle du bit a lire , de 31 a 0
; nb bits à lire
;
; tmp1 =  position actuelle du bit a lire - nb bits à lire 
; si positif, lire nb bits à lire , de position actuelle en bit à position actuelle en bit - nb bits à lire : un mask complet, sharq (position actuelle en bit - nb bits à lire) // puis shlq (position actuelle en bit - nb bits à lire) // puis shlq (31-position actuelle en bit)
; si négatif, lire (nb bits à lire+ tmp1) : 

DSP__AHX_decode_streaming_V3__read_bits_from_bits_streaming:
; 32 bits maxi
	moveq		#0,DSP__decode_bits__tmp3				; bits de la premiere lecture, << 
	move			DSP__decode_bits__numero_bit_actuel,DSP__decode_bits__tmp1
	load			(DSP__decode_bits__pointeur_lecture_bits),DSP__decode_bits__tmp0
	addq			#1,DSP__decode_bits__tmp1
	sub				DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__tmp1
	movei		#DSP__AHX_decode_streaming_V3__read_bits_from_bits_streaming__sans_relecture,DSP__decode_bits__tmp2
	cmpq			#0,DSP__decode_bits__tmp1
	jump			pl,(DSP__decode_bits__tmp2)
	nop
	jump			eq,(DSP__decode_bits__tmp2)
	nop
; DSP__decode_bits__tmp1 négatif
; il ne faut lire que DSP__decode_bits__nb_bits_a_lire - DSP__decode_bits__tmp1 bits puis incrementer le pointeur source de 4, puis mettre à jour DSP__decode_bits__tmp1, mettre 31 dans DSP__decode_bits__numero_bit_actuel
; les bits sont en bas de DSP__decode_bits__tmp0

; ne garder que les bits du bas. shift gauche, puis shift droite
; 
	move			DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__tmp2
	add				DSP__decode_bits__tmp1,DSP__decode_bits__tmp2
	movei		#32,DSP__decode_bits__tmp3
	sub				DSP__decode_bits__tmp2,DSP__decode_bits__tmp3
	neg				DSP__decode_bits__tmp3
; vers la gauche
	sh				DSP__decode_bits__tmp3,DSP__decode_bits__tmp0
; vers la droite	
	neg				DSP__decode_bits__tmp3			
	sh				DSP__decode_bits__tmp3,DSP__decode_bits__tmp0
; vers la gauche  car tmp1 est negatif
	sh				DSP__decode_bits__tmp1,DSP__decode_bits__tmp0
	move			DSP__decode_bits__tmp0,DSP__decode_bits__tmp3
; tmp3 = bits du haut, décalés
	addq			#4,DSP__decode_bits__pointeur_lecture_bits
	load			(DSP__decode_bits__pointeur_lecture_bits),DSP__decode_bits__tmp0

	sub				DSP__decode_bits__tmp2,DSP__decode_bits__nb_bits_a_lire
	movei		#32,DSP__decode_bits__tmp1
	moveq		#31,DSP__decode_bits__numero_bit_actuel
	sub				DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__tmp1

DSP__AHX_decode_streaming_V3__read_bits_from_bits_streaming__sans_relecture:
; DSP__decode_bits__tmp1=position apres le dernier bit a lire
; positif => right
	subq			#1,DSP__decode_bits__tmp1
	sh				DSP__decode_bits__tmp1,DSP__decode_bits__tmp0
	neg				DSP__decode_bits__tmp1
; vers la gauche	
	sh				DSP__decode_bits__tmp1,DSP__decode_bits__tmp0
	moveq		#31,DSP__decode_bits__tmp1
	sub				DSP__decode_bits__numero_bit_actuel,DSP__decode_bits__tmp1
; vers la gauche	
	neg				DSP__decode_bits__tmp1
	sh				DSP__decode_bits__tmp1,DSP__decode_bits__tmp0
;  les bits sont tout en haut a gauche
	movei		#32,DSP__decode_bits__tmp1
	sub				DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__tmp1
; a droite	
	sh				DSP__decode_bits__tmp1,DSP__decode_bits__tmp0	
	
	or				DSP__decode_bits__tmp3,DSP__decode_bits__tmp0

	sub				DSP__decode_bits__nb_bits_a_lire,DSP__decode_bits__numero_bit_actuel

	move			DSP__decode_bits__tmp0,DSP__decode_bits__bits_resultat

	jump		(DSP__decode_bits__adresse_retour)
	nop


DSP__AHX_decode_streaming_V2__read_bits_from_bits_streaming:
	
	;movei		#pointeur_actuel_sur_AHX_streaming_bits,R18
	;movei		#numero_bit_actuel_dans_streaming_bits,R17
	;load		(R18),R10
	;move		R0,R13
	;load		(R17),R12
	moveq		#0,DSP__decode_bits__bits_resultat
	loadb		(DSP__decode_bits__pointeur_lecture_bits),DSP__decode_bits__tmp0							; lecture d'un octet
	;movei		#DSP__AHX_read_bits_from_bits_streaming__boucle,R19

DSP__AHX_read_bits_from_bits_streaming__boucle:
	move		DSP__decode_bits__tmp0,DSP__decode_bits__tmp1
	sh			DSP__decode_bits__numero_bit_actuel,DSP__decode_bits__tmp1
	btst		#0,DSP__decode_bits__tmp1
	jr			eq,DSP__AHX_read_bits_from_bits_streaming__boucle__bit_entrant_a_zero
	add			DSP__decode_bits__bits_resultat,DSP__decode_bits__bits_resultat					; decale vers la gauche
	addq		#1,DSP__decode_bits__bits_resultat					; insere un bit
DSP__AHX_read_bits_from_bits_streaming__boucle__bit_entrant_a_zero:
	subq		#1,DSP__decode_bits__numero_bit_actuel
	jr			pl, DSP__AHX_read_bits_from_bits_streaming__pas_fin_de_l_octet_actuel
	nop
	jr			eq,DSP__AHX_read_bits_from_bits_streaming__pas_fin_de_l_octet_actuel
	nop
	addq			#1,DSP__decode_bits__pointeur_lecture_bits
	loadb		(DSP__decode_bits__pointeur_lecture_bits),DSP__decode_bits__tmp0						; lecture d'un nouvel octet
	moveq		#8-1,DSP__decode_bits__numero_bit_actuel

DSP__AHX_read_bits_from_bits_streaming__pas_fin_de_l_octet_actuel:
	subq		#1,DSP__decode_bits__nb_bits_a_lire
	jump		ne,(DSP__decode_bits__adresse_boucle_lecture_bits)
	nop

	;store		R10,(R18)
	jump		(DSP__decode_bits__adresse_retour)
	nop
	;store		R12,(R17)


; ---------------------------------------- DSP Datas
	.phrase
AHX_DSP_Seed_Noise:									dc.l			"AYS!"
	
AHX_table_routines_a_executer:
		dc.l			AHX_DSP_remplissage_buffer_triangle		;AHX_DSP_remplissage_buffer_triangle
		dc.l			AHX_DSP_remplissage_buffer_sawtooth		;AHX_DSP_remplissage_buffer_sawtooth
		dc.l			AHX_DSP_remplissage_buffer_square
		dc.l			AHX_DSP_remplissage_buffer_noise
	
	
HIVELY_datas_channels:
		.rept		NB_channels
		dc.l			0									; vc_AudioVolume			0
		dc.l			0									; vc_Waveform					4
		dc.l			0									; vc_SquarePos				8
		dc.l			0									; vc_WaveLength				12
		dc.l			0									; vc_FilterPos				16
		dc.l			0									; vc_AudioPeriod			20
		dc.l			1									; channel on ou off ?	24
		dc.l			0									; vc_RingWaveform
		dc.l			0									; vc_RingAudioPeriod
		; Ring Modulation : vc_Waveform+vc_WaveLength+vc_AudioPeriod 
		.endr


; index_AHX_enregistrements_N_voies__I2S__offset=0
; index_AHX_enregistrements_N_voies__I2S__increment=1
; index_AHX_enregistrements_N_voies__I2S__mask_bouclage=2
; index_AHX_enregistrements_N_voies__I2S__buffer=3
	
; format de datas pour le replay I2S	
AHX_enregistrements_N_voies:
i			set				0
		.rept		NB_channels
		dc.l		0																										; offset
		dc.l		0																										; increment
		dc.l		$7F<<AHX_nb_bits_virgule_increment_period		; mask bouclage	
		dc.l		buffer_128_1																			; pointeur buffer
		dc.l		255																										; panning left
		dc.l		255																										; panning right
		dc.l		0																										; offset RM
		dc.l		0																										; increment RM
		dc.l		DSP_hively_buffers_RM+(i*128*4)									; pointeur buffer RM
i		set		i+1
		.endr	

DSP__HVL_table_panning_voies_de_base:
index			set				0
		.rept		NB_channels
		dc.l			HIVELY_datas_channels+(DSP_offset_vc__total*index)				; gauche = voie 1
index			set		index+1
		.endr
		
		
DSP_flag_replay_ON_OFF:												dc.l				0				; 0= running / 1=i2S en cours d'arret / 2=timer1 en cours d'arret / 3=main en cours d'arret / 4=totalement arreté
DSP_frequence_de_replay_reelle_I2S:					dc.l				0
DSP_ratio_Amiga_Jaguar__a_virgule_9_bits:		dc.l				0
DSP_parametre_de_frequence_I2S:								dc.l				0

; gestion du stream
pointeur_actuel_sur_AHX_streaming_bits:			dc.l			module_AHX_streaming_bits
numero_bit_actuel_dans_streaming_bits:			dc.l			31			; de 31 => 0


AHX_DSP_flag_timer1:										dc.l			0


buffer_temp_wave:		dcb.l		128,128
; NB_channels fois 128 .L , buffers à mixer
buffer_128_1:			dcb.l		128*NB_channels,128


; test acces ram
; DSP_memory_W_test_original:				dc.l					$12345678
; DSP_memory_W_test_resultat:				dc.l					0



;---------------------
; FIN DE LA RAM DSP
code_DSP_fin:
;---------------------


SOUND_DRIVER_SIZE			.equ			code_DSP_fin-DSP_base_memoire
	.print	"; ------------------------------------------------------------------------------------------------"
	.print	"--- Sound driver code size (DSP): ", /u SOUND_DRIVER_SIZE, " bytes / 8192 ---"
	.print	"; ------------------------------------------------------------------------------------------------"


	.68000


;--------------------------
; VBL

VBL:
                movem.l 	a0-a1,-(a7)
				
				lea				ob_liste_originale,a0
				lea				ob_list_courante,a1
vbl_copy_oblist:
				move.w		(a0)+,(a1)+
				cmp.l		#fin_ob_liste_originale,a0
				blt.s		vbl_copy_oblist
				
				
                ;jsr     copy_olist              	; use Blitter to update active list from shadow

                addq.l	#1,vbl_counter

                ;move.w  #$101,INT1              	; Signal we're done
.exit:
                movem.l (a7)+,a0-a1
				move.w	#$101,INT1
                move.w  #$0,INT2
                rte

; ---------------------------------------
; imprime une chaine terminée par un zéro
; a0=pointeur sur chaine
print_string:
	movem.l d0-d7/a0-a6,-(a7)	

print_string_boucle:
	moveq	#0,d0
	move.b	(a0)+,d0
	cmp.w	#0,d0
	bne.s	print_string_pas_fin_de_chaine
	movem.l (a7)+,d0-d7/a0-a6
	rts
print_string_pas_fin_de_chaine:
	bsr		print_caractere
	bra.s	print_string_boucle

; ---------------------------------------
; imprime une chaine qui commence par le nb de caractere de la chaine
; a0=pointeur sur chaine “sized string”
print_string__sstring:
	movem.l d0-d7/a0-a6,-(a7)	

	moveq		#0,d0
	moveq		#0,d7
	move.b		(a0)+,d7
	subq.w		#1,d7
	
print_string__sstring__boucle:
	move.b		(a0)+,d0
	bsr			print_caractere
	dbf			d7,print_string__sstring__boucle
	movem.l 	(a7)+,d0-d7/a0-a6
	rts


; ---------------------------------------
; imprime un nombre HEXA de 2 chiffres
print_nombre_hexa_2_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	lea		convert_hexa,a0
	move.l		d0,d1
	divu		#16,d0
	and.l		#$F,d0			; limite a 0-15
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	and.l		#$F,d0			; limite a 0-15
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts
	
convert_hexa:
	dc.b		48,49,50,51,52,53,54,55,56,57
	dc.b		65,66,67,68,69,70
	
; ---------------------------------------
; imprime un nombre de 2 chiffres
print_nombre_2_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	cmp.l		#0,d0
	beq.s		.zap
	add.l		#48,d0
	bsr			print_caractere
.zap:
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 3 chiffres
print_nombre_3_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	cmp.l		#0,d0
	beq.s		.zap
	add.l		#48,d0
	bsr			print_caractere
.zap:
	move.l		d1,d0	
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts


; ---------------------------------------
; imprime un nombre de 2 chiffres , 00
print_nombre_2_chiffres_force:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 4 chiffres HEXA
print_nombre_hexa_4_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1
	lea		convert_hexa,a0

	divu		#4096,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#4096,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#256,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#256,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#16,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 6 chiffres HEXA ( pour les adresses memoire)
print_nombre_hexa_6_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	
	move.l		d0,d1
	lea		convert_hexa,a0

	swap		d0
	and.l		#$F0,d0
	lsr.l		#4,d0
	and.l		#$F,d0
	and.l		#$FFFFF,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	swap		d0
	and.l		#$F,d0
	and.l		#$FFFF,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#4096,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#4096,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#256,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#256,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#16,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#16,d2
	sub.l		d2,d1
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	move.l		d1,d0
	move.b		(a0,d0.w),d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts


; ---------------------------------------
; imprime un nombre de 4 chiffres
print_nombre_4_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#1000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#1000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere

	move.l		d1,d0
	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere


	move.l		d1,d0
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr			print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr			print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts

; ---------------------------------------
; imprime un nombre de 5 chiffres
print_nombre_5_chiffres:
	movem.l d0-d7/a0-a6,-(a7)
	move.l		d0,d1

	divu		#10000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere

	move.l		d1,d0
	divu		#1000,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#1000,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere

	move.l		d1,d0
	divu		#100,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#100,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere


	move.l		d1,d0
	divu		#10,d0
	and.l		#$FF,d0
	move.l		d0,d2
	mulu		#10,d2
	sub.l		d2,d1
	add.l		#48,d0
	bsr.s		print_caractere
	move.l		d1,d0
	add.l		#48,d0
	bsr.s	print_caractere
	movem.l (a7)+,d0-d7/a0-a6
	rts



; -----------------------------
; copie un caractere a l ecran
; d0.w=caractere
;
; 00=CLS
; 09 = retour debut de ligne
; 10 = retour chariot

print_caractere:
	movem.l d0-d7/a0-a6,-(a7)
	cmp.b	#00,d0
	bne.s	print_caractere_pas_CLS

; cls
	moveq		#0,d0
	lea			ecran1,a0
	move.w	#((320*256)/4)-1,d7
print_caractere_cls:	
	move.l	d0,(a0)+
	dbf			d7,print_caractere_cls
	movem.l (a7)+,d0-d7/a0-a6
	rts
	
print_caractere_pas_CLS:

	cmp.b	#10,d0
	bne.s	print_caractere_pas_retourchariot
	move.w	#0,curseur_x
	add.w	#8,curseur_y
	movem.l (a7)+,d0-d7/a0-a6
	rts

print_caractere_pas_retourchariot:
	cmp.b	#09,d0
	bne.s	print_caractere_pas_retourdebutligne
	move.w	#0,curseur_x
	movem.l (a7)+,d0-d7/a0-a6
	rts

print_caractere_pas_retourdebutligne:

	lea		ecran1,a1
	moveq	#0,d1
	move.w	curseur_x,d1
	add.l	d1,a1
	moveq	#0,d1
	move.w	curseur_y,d1
	mulu	#nb_octets_par_ligne,d1
	add.l	d1,a1

	lsl.l	#3,d0		; * 8
	lea		fonte,a0
	add.l	d0,a0
	
	
; copie 1 lettre
	move.l	#8-1,d0
copieC_ligne:
	moveq	#8-1,d1
	move.b	(a0)+,d2
copieC_colonne:
	moveq	#0,d4
	btst	d1,d2
	beq.s	pixel_a_zero
	move.b	couleur_char,d4
pixel_a_zero:
	move.b	d4,(a1)+
	dbf		d1,copieC_colonne
	lea		nb_octets_par_ligne-8(a1),a1
	dbf		d0,copieC_ligne

	move.w	curseur_x,d0
	add.w	#8,d0
	cmp.w	#320,d0
	blt.s		curseur_pas_fin_de_ligne
	moveq	#0,d0
	add.w	#8,curseur_y
curseur_pas_fin_de_ligne:
	move.w	d0,curseur_x

	movem.l (a7)+,d0-d7/a0-a6

	rts


;----------------------------------
; recopie l'object list dans la courante

copy_olist:
				move.l	#ob_list_courante,A1_BASE			; = DEST
				move.l	#$0,A1_PIXEL
				move.l	#PIXEL16|XADDPHR|PITCH1,A1_FLAGS
				move.l	#ob_liste_originale,A2_BASE			; = source
				move.l	#$0,A2_PIXEL
				move.l	#PIXEL16|XADDPHR|PITCH1,A2_FLAGS
				move.w	#1,d0
				swap	d0
				move.l	#fin_ob_liste_originale-ob_liste_originale,d1
				move.w	d1,d0
				move.l	d0,B_COUNT
				move.l	#LFU_REPLACE|SRCEN,B_CMD
				rts


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Procedure: InitVideo (same as in vidinit.s)
;;            Build values for hdb, hde, vdb, and vde and store them.
;;

InitVideo:
                movem.l d0-d6,-(sp)

				
				move.w	#-1,ntsc_flag
				move.l	#50,_50ou60hertz
	
				move.w  CONFIG,d0                ; Also is joystick register
                andi.w  #VIDTYPE,d0              ; 0 = PAL, 1 = NTSC
                beq.s     .palvals
				move.w	#1,ntsc_flag
				move.l	#60,_50ou60hertz
	

.ntscvals:		move.w  #NTSC_HMID,d2
                move.w  #NTSC_WIDTH,d0

                move.w  #NTSC_VMID,d6
                move.w  #NTSC_HEIGHT,d4
				
                bra.s    calc_vals
.palvals:
				move.w #PAL_HMID,d2
				move.w #PAL_WIDTH,d0

				move.w #PAL_VMID,d6				
				move.w #PAL_HEIGHT,d4

				
calc_vals:		
                move.w  d0,width
                move.w  d4,height
                move.w  d0,d1
                asr     #1,d1                   ; Width/2
                sub.w   d1,d2                   ; Mid - Width/2
                add.w   #4,d2                   ; (Mid - Width/2)+4
                sub.w   #1,d1                   ; Width/2 - 1
                ori.w   #$400,d1                ; (Width/2 - 1)|$400
                move.w  d1,a_hde
                move.w  d1,HDE
                move.w  d2,a_hdb
                move.w  d2,HDB1
                move.w  d2,HDB2
                move.w  d6,d5
                sub.w   d4,d5
                add.w   #16,d5
                move.w  d5,a_vdb
                add.w   d4,d6
                move.w  d6,a_vde
			
			    move.w  a_vdb,VDB
				move.w  a_vde,VDE    
				
				
				move.l  #0,BORD1                ; Black border
                move.w  #0,BG                   ; Init line buffer to black
                movem.l (sp)+,d0-d6
                rts



        .68000
		

;-----------------
; datas
curseur_Y_min			.equ		8
curseur_x:				dc.w		0
curseur_y:				dc.w		curseur_Y_min
couleur_char:				dc.b		25
	even

		.dphrase
ob_liste_originale:           				 ; This is the label you will use to address this in 68K code
        .objproc 							   ; Engage the OP assembler
		.dphrase

        .org    ob_list_courante			 ; Tell the OP assembler where the list will execute
;
        branch      VC < 0, .stahp    			 ; Branch to the STOP object if VC < 0
        branch      VC > 265, .stahp   			 ; Branch to the STOP object if VC > 241
			; bitmap data addr, xloc, yloc, dwidth, iwidth, iheight, bpp, pallete idx, flags, firstpix, pitch
        bitmap      ecran1, 16, 26, nb_octets_par_ligne/8, nb_octets_par_ligne/8, 146-26,3				; 246-26
		;bitmap		ecran1,16,24,40,40,255,3
        jump        .haha
.stahp:
        stop
.haha:
        jump        .stahp
		
		.68000
		.dphrase
fin_ob_liste_originale:

	.phrase

	.phrase
chaine_debut_init_AHX:			dc.b	"Init AHX",10,0
chaine_songname:					dc.b	"songname : ",0
chaine_V3:							dc.b	"hively V1.0 : streaming DSP bits",10,0
chaine_start_playing:			dc.b	"Now playing...",10,0
chaine_position:				dc.b	"position : ",0
chaine_freq:					dc.b	"Replay frequency : ",0
chaine_HZ:						dc.b	" Hz",10,0
chaine_RAM_DSP:				dc.b	"DSP RAM available while running : ",0
chaine_centrale:				dc.b	"RAM used : ",0
chaine_nb_channels:			dc.b		"number of voices : ",0
chaine_frequence:				dc.b		"AHX/Hively freq : ",0
chaine_50hz:			dc.b			"50 Hz",10,0
chaine_100hz:			dc.b			"100 Hz",10,0
chaine_150hz:			dc.b			"150 Hz",10,0
chaine_200hz:			dc.b			"200 Hz",10,0
	.even
	; = plyPSpeed / If SPD=0, the mod plays at 50Hz //  SPD=1, 100Hz. SPD=2, 150Hz. SPD=3, 200Hz
	table_chaines_hertz:
		dc.l				chaine_50hz
		dc.l				chaine_100hz
		dc.l				chaine_150hz
		dc.l				chaine_200hz
		
	
	.phrase
fonte:	
	.include	"fonte1plan.s"
	even



; datas DSP
	.phrase
HVL_speed_multiplier:				dc.l					speed_multiplier
debut_ram_libre_DSP:		dc.l			code_DSP_fin
numero_de_frame_DSP:					dc.l			0	


	.phrase
binPrecalcTable:
	.incbin		"AHX_FilterPrecalcTable.w.BIN"				; 5580 octets = 2790 .w
	.phrase


Hively_panning_left:
; table panning left 0 a 255
    dc.b                254,254,254,254,254,254,254,254,254,254,254,254,254,254,254,253
    dc.b                253,253,253,253,253,252,252,252,252,252,251,251,251,250,250,250
    dc.b                250,249,249,249,248,248,248,247,247,246,246,246,245,245,244,244
    dc.b                244,243,243,242,242,241,241,240,240,239,239,238,237,237,236,236
    dc.b                235,234,234,233,233,232,231,231,230,229,229,228,227,227,226,225
    dc.b                224,224,223,222,221,221,220,219,218,217,217,216,215,214,213,212
    dc.b                212,211,210,209,208,207,206,205,204,203,202,201,201,200,199,198
    dc.b                197,196,195,194,193,192,191,189,188,187,186,185,184,183,182,181
    dc.b                180,179,178,176,175,174,173,172,171,170,168,167,166,165,164,162
    dc.b                161,160,159,158,156,155,154,153,151,150,149,148,146,145,144,142
    dc.b                141,140,139,137,136,135,133,132,131,129,128,127,125,124,122,121
    dc.b                120,118,117,116,114,113,111,110,109,107,106,104,103,101,100,99
    dc.b                97,96,94,93,91,90,88,87,85,84,82,81,79,78,77,75
    dc.b                74,72,71,69,68,66,64,63,61,60,58,57,55,54,52,51
    dc.b                49,48,46,45,43,42,40,38,37,35,34,32,31,29,28,26
    dc.b                24,23,21,20,18,17,15,14,12,10,9,7,6,4,3,0
Hively_panning_right:
; table panning right 0 a 255
    dc.b                0,1,3,4,6,7,9,10,12,14,15,17,18,20,21,23
    dc.b                24,26,28,29,31,32,34,35,37,38,40,42,43,45,46,48
    dc.b                49,51,52,54,55,57,58,60,61,63,64,66,68,69,71,72
    dc.b                74,75,77,78,79,81,82,84,85,87,88,90,91,93,94,96
    dc.b                97,99,100,101,103,104,106,107,109,110,111,113,114,116,117,118
    dc.b                120,121,122,124,125,127,128,129,131,132,133,135,136,137,139,140
    dc.b                141,142,144,145,146,148,149,150,151,153,154,155,156,158,159,160
    dc.b                161,162,164,165,166,167,168,170,171,172,173,174,175,176,178,179
    dc.b                180,181,182,183,184,185,186,187,188,189,191,192,193,194,195,196
    dc.b                197,198,199,200,201,201,202,203,204,205,206,207,208,209,210,211
    dc.b                212,212,213,214,215,216,217,217,218,219,220,221,221,222,223,224
    dc.b                224,225,226,227,227,228,229,229,230,231,231,232,233,233,234,234
    dc.b                235,236,236,237,237,238,239,239,240,240,241,241,242,242,243,243
    dc.b                244,244,244,245,245,246,246,246,247,247,248,248,248,249,249,249
    dc.b                250,250,250,250,251,251,251,252,252,252,252,252,253,253,253,253
    dc.b                253,253,254,254,254,254,254,254,254,254,254,254,254,254,254,254

.phrase
module_AHX_streaming_bits:
		;.incbin		"C:/Jaguar/AHX_streamed/EDZ.ahx.streambits"					; bits streamed			4 voies

		;.incbin		"C:/Jaguar/AHX_streamed/menu0101.hvl.streambits"					; bits streamed			10 voies

; debug 10 voies
;		.incbin		"c:/jaguar/AHX_streamed/edz.hvl.streambits"

		 ;.incbin		"c:/jaguar/AHX_streamed/headcrash_debug.hvl.streambits"				; OK 6 voies
		
		; test RM
		;.incbin			"C:/Jaguar/hivelytracker/ht19_win32/Songs/Xeron/rmtest.hvl.streambits"
		
		; forsaken final
		;.incbin		"C:/Jaguar/hivelytracker/ht19_win32/Songs/Virgill/forsaken.hvl.streambits"
		
		;gone
		.incbin		"c:\jaguar\ahx\gone (filtered).ahx.streambits"
		
	
	;.incbin		"C:/jaguar/AHX_streamed/einlhauf_4v.streambits"				; 4 voies
		even
fin_module_AHX_streaming_bits:
		dc.l				0,0,0,0
		dc.l				0,0,0,0
	.phrase

;test_lecture_bits:
;		dc.w				$ABCD
;		dc.w				$1234
;		dc.w				$5678
;		dc.w				0,0,0,0
;.phrase




;------------ BSS
	.bss
	.phrase
DEBUT_BSS:
	.phrase
; buffers RM
DSP_hively_buffers_RM:
	ds.l				128*NB_channels
	

.phrase
frequence_Video_Clock:					ds.l				1
frequence_Video_Clock_divisee :			.ds.l				1



_50ou60hertz:			ds.l	1
ntsc_flag:				ds.w	1
a_hdb:          		ds.w   1
a_hde:          		ds.w   1
a_vdb:          		ds.w   1
a_vde:          		ds.w   1
width:          		ds.w   1
height:         		ds.w   1
taille_liste_OP:		ds.l	1
vbl_counter:			ds.l	1

FIN_RAM_before_screen:
            .dphrase
ecran1:				ds.b		320*256				; 8 bitplanes

FIN_RAM:

