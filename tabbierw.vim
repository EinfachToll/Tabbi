"Vim plugin for aligning text
"Version:			1.1
"Last Change:		Oct 17, 2010
"Author:			Daniel Schemala
"Report bugs to:	sehrpositiv@web.de
"Usage:
"		- type :Tabbi for aligning the text, a range before the command and visual mode are supported
"		- :call Tabb("- §2:§-§1 - §4") for formatting selected lines, lines are splittet by one or more tabs or two or more whitespaces
"		- :call Tabb(pattern, ',') formatting, lines are splitted by commas. Regex are allowed. Put in single quotes.
"		- :call Tabb(pattern, separator, 0) as above, but segments are not trimmed

"ZUTUN:
"- gucken, welche Zeilen man von Formatieren und Einrücken ausschließen kann (Überschriften)
"	- evtl. die Zeilen unter ner Leerzeile
"	- Leerzeilen
"	- Zeilen mit nur 1 Segment, wenn alle anderen mehr haben
"- bissl schöner anordnen
"	- zu große Abstände vermeiden
"	- möglichst viele Zeilen auf gleicher Höhe
"
"- evtl. auf rechteckige Auswahl beschränken
"- ne Möglichkeit, Zeilennummer einzufügen

if exists("loaded_tabbi") || &cp
	finish
endif
let loaded_tabbi=1

command! -range Tabbi call s:TabbiAUF(<line1>, <line2>)

function! Tabb(muster, ...) range
	let l:tr = exists("a:1") ? a:1 : '\t\+\|\s{2,}'
	let l:schn = exists("a:2") ? a:2 : 1
	let s:ERSTEZ = a:firstline
	let s:LETZTEZ = a:lastline
	let l:muli = []
	let l:we=-1
	"let l:muli = split(a:muster, '\(\ze§\d\+\)\|\(§\d\+\zs\)', 1)
	while 1
		let l:wa = match(a:muster, '\(\(^\|[^\\]\)\zs§\d\)\|$', l:we)
		let l:muli += [strpart(a:muster, l:we+1, l:wa-l:we-1)]
		let l:we = match(a:muster, '\d\(\D\|$\)', l:wa)
		if l:we==-1
			break
		endif
		let l:muli += [strpart(a:muster, l:wa+2, l:we-l:wa-1)]
	endwhile
	let l:tabbil = []
	let s:PUFFERLISTE = []
	for l:zn in range(s:ERSTEZ, s:LETZTEZ)
		let l:zeile = getline(l:zn)
		let l:neuzei = ""
		let l:li = split(l:zeile, l:tr, 1)
		let l:i = 0
		while l:i < len(l:muli)-1
			let l:neuzei .= l:muli[l:i]
			let l:za = l:muli[l:i+1]
			if l:za > 0 && l:za <= len(l:li)
				let l:st=l:schn ? substitute(l:li[l:za-1], "^\\s\\+\\|\\s\\+$","","g") : l:li[l:za-1]
			else
				let l:st = ""
			endif
			let l:neuzei .= l:st
			let l:i += 2
		endwhile
		let l:neuzei .= l:muli[len(l:muli)-1]
		let l:tabbilz = split(l:neuzei, "§-", 1)
		call add(s:PUFFERLISTE, l:tabbilz)
	endfor
	call s:TabbiL()
endfunction

function! s:TabbiAUF(erstez, letztez)
	let s:ERSTEZ = a:erstez
	let s:LETZTEZ = a:letztez
	if s:ERSTEZ >= s:LETZTEZ
		let s:ERSTEZ = 1
		let s:LETZTEZ = line("$")
	endif
	let s:PUFFERLISTE = []
	for l:i in range(s:ERSTEZ, s:LETZTEZ)
		call add(s:PUFFERLISTE, split(getline(l:i), '\(\t\+\)\|\(\s\s\+\)', 1))
	endfor
	"call s:Ueberlegen()
	"call s:TabbiL()
	call s:Opti()
endfunction
	

function! s:TabbiL()
	let s:LISTEMAX = []
	for l:zeile in range(len(s:PUFFERLISTE))
		for l:i in range(len(s:PUFFERLISTE[l:zeile]))
			let l:br = s:AUSSCHL[l:zeile] > 1 ? 0 : len(substitute(s:PUFFERLISTE[l:zeile][l:i], ".", "d", "g"))
			if l:i >= len(s:LISTEMAX)
				call add(s:LISTEMAX, l:br)
			else
				let s:LISTEMAX[l:i] = max([s:LISTEMAX[l:i], l:br])
			endif
		endfor
	endfor
	call s:TabbiT()
endfunction

function! s:Auf(som, so)
	if &expandtab
		let l:mb = (a:som % &ts)==&ts-1 ? a:som+&ts+1 : a:som+&ts-(a:som % &ts)
		let l:ov = (a:som - a:so)/&ts + &ts-(a:so % &ts)
		return repeat(" ", l:mb-a:so)
	else
   		let l:mb = (a:som % &ts)==&ts-1 ? a:som+&ts+1 : a:som+&ts-(a:som % &ts)
   		let l:at = ((a:so%&ts)==0 ? 0 : 1) + (l:mb-a:so)/&ts
		return repeat("\t", l:at)
	endif
endfunction

function! s:TabbiT() "ersteZ, letzteZ)
	for l:zn in range(len (s:PUFFERLISTE))
		let l:neuzei=""
		let l:zeilel=s:PUFFERLISTE[l:zn]
		for l:i in range(len(l:zeilel))
			let l:neuzei .=  l:zeilel[l:i]
			if l:i<len(l:zeilel)-1
				let l:neuzei .= s:Auf(s:LISTEMAX[l:i], len(substitute(l:zeilel[l:i], ".", "d", "g")))
			endif
		endfor
		call setline(l:zn+s:ERSTEZ, l:neuzei)
	endfor
endfunction

function! s:Ueberlegen()
	let s:AUSSCHL = []
	let l:anz = 0
	let l:anzrz = 0
	for l:i in range(1, len(s:PUFFERLISTE))
		if s:AnzSeg(l:i-1) > 0 && s:AnzSeg(l:i)==1
			let l:anz += 1
			let l:anzrz += 1
			continue
		endif
		if s:AnzSeg(l:i) > 0
			let l:anzrz += 1
		endif
	endfor
	echo l:anz
	echo l:anzrz
	let l:anz = (100*l:anz) / l:anzrz
	for l:i in range(len(s:PUFFERLISTE))
		if (l:i==0 || s:AnzSeg(l:i-1)==0) && s:AnzSeg(l:i)==1
			call add(s:AUSSCHL, s:AnzSeg(l:i+2) + s:AnzSeg(l:i+3))
		else
			if s:AnzSeg(l:i)==0
				call add(s:AUSSCHL, 10)
			else
				call add(s:AUSSCHL, 0)
			endif
		endif
	endfor
	echo s:AUSSCHL
	echo l:anz
endfunction

function! s:AnzSeg(i)
	return a:i >= len(s:PUFFERLISTE) || s:PUFFERLISTE[a:i][0] =~ '^\s*$' ? 0 : len(s:PUFFERLISTE[a:i])
endfunction

function! s:Opti()
	let l:anzdtei = 2
	let s:REIHE = 0
	let l:mat = []
	let l:hilfi = []
	for l:i in range(l:anzdtei)
		call add(l:hilfi,0)
	endfor
	for l:i in range(len(s:PUFFERLISTE)) "Initialisieren
		call add(l:mat, copy(l:hilfi))
	endfor
	for l:y in range(1, len(l:mat)-1)
		let l:mat[l:y][0] = s:Abst(0, l:y)
	endfor
	call setline(5, string(l:mat))
	for l:x in range(1, l:anzdtei-1)
		for l:y in range(l:x+1, len(l:mat)-1)
			let l:mat[l:y][l:x] = min([l:mat[l:y-1][l:x] + s:Abst(l:y-1, l:y), l:mat[l:y-1][l:x-1] + s:Abst(l:y, l:y)]) 
		endfor
	endfor
	call setline(6, string(l:mat))
endfunction

function! s:Abst(von, bis)
	let l:mini = 10000
	let l:maxi = 0
	for l:i in range(a:von, a:bis)
		let l:mini = min([len(s:PUFFERLISTE[l:i][s:REIHE]), l:mini])
		let l:maxi = max([len(s:PUFFERLISTE[l:i][s:REIHE]), l:maxi])
	endfor
	let l:mb = (l:maxi % &ts)==&ts-1 ? l:maxi+&ts+1 : l:maxi+&ts-(l:maxi % &ts)
	let l:ov = (l:maxi - l:mini)/&ts + &ts-(l:mini % &ts)
	return l:mb-l:mini  "das sollte jetzt die Differenz zw. Maximum und Minimum sein
endfunction
