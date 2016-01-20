client/verb/vendgen()
	set category = "Debug"
	set name = "Vender JSON"

	// generate names file
	fdel("vtypes.json")
	var/txt = "{"
	for(var/type in typesof(/obj/machinery/vending))
		var/obj/inst = new type()
		txt += {""[type]":"[inst.name]","}
		qdel(inst)
	txt = copytext(txt, 1, length(txt))
	txt += "}"
	file("vtypes.json") << txt

	// generate full listing
	fdel("vinsts.json")
	txt = "\["
	for(var/obj/machinery/vending/O)
		if(O.z == 1)
			txt += {"{"type":"[O.type]","loc":\[[O.x],[O.y]\]},"}
	txt = copytext(txt, 1, length(txt))
	txt += "\]"
	file("vinsts.json") << txt

client/verb/areagen()
	set category = "Debug"
	set name = "Area JSON"

	// generate areas file
	fdel("areas.json")
	var/txt = "\["
	for(var/type in typesof(/area))
		var/area/inst = new type()
		txt += {""[inst.name]","}
		qdel(inst)
	txt = copytext(txt, 1, length(txt))
	txt += "\]"
	file("areas.json") << txt

// generate ALL MAP TILES
client/verb/genmapall()
	set category = "Debug"
	set name = "Generate Map All Zooms"

	genmap()
	for(var/i = 4; i >= 2; i--)
		genmapzooms(i)

// generate the zoomed out tiles
client/verb/genmapzooms(z as num)
	set category = "Debug"
	set name = "Generate Map Zoom"

	// figure out output grid size
	var/size = 32 / 2 ** (5 - z)

	for(var/x = 0; x < size; x++)
		world << "[x]"
		for(var/y = 0; y < size; y++)
			var/icon/res = icon('icons/effects/96x96.dmi', "")
			res.Scale(256, 256)
			// Initialize to black.
			res.Blend("#000", ICON_OVERLAY)
			var/icon/i = icon("./tiles/[z+1]/[round(x*2)]/[round(y*2)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=1,y=1)
			i = icon("./tiles/[z+1]/[round(x*2+1)]/[round(y*2)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=129,y=1)
			i = icon("./tiles/[z+1]/[round(x*2)]/[round(y*2+1)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=1,y=129)
			i = icon("./tiles/[z+1]/[round(x*2+1)]/[round(y*2+1)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=129,y=129)
			fcopy(res, "./tiles/[z]/[round(x)]/[round(y)].png")

// generate the 1:1 zoom tiles
client/verb/genmap()
	set category = "Debug"
	set name = "Generate Map 5"

	for(var/x = 1; x <= 255; x += 8)
		world << "[x]"
		for(var/y = 1; y <= 255; y += 8)
			var/icon/I = map_get_icon(
				block(locate(max(1,x - 1), max(1,y - 1), 1),locate(min(255,x + 8), min(255,y + 8), 1)),
				locate(x + 3.5, y + 3.5, 1))
			fcopy(new/icon(I, "", SOUTH, 1, 0),
				"./tiles/5/[round(x/8)]/[round(y/8)].png")

client/proc/map_get_icon(list/turfs, turf/center)
	var/icon/res = icon('icons/effects/96x96.dmi', "")
	res.Scale(8*32, 8*32)
	// Initialize to black.
	res.Blend("#151515", ICON_OVERLAY)

	var/atoms[] = list()
	for(var/turf/the_turf in turfs)
		// Add outselves to the list of stuff to draw
		atoms.Add(the_turf);
		// As well as anything that isn't invisible.
		for(var/atom/A in the_turf)
			if(!A.invisibility)
				atoms.Add(A)

	// Sort the atoms into their layers
	var/list/sorted = sort_atoms_by_layer(atoms)
	var/center_offset = 3 * 32
	for(var/i; i <= sorted.len; i++)
		var/atom/A = sorted[i]
		if(A)
			var/icon/img = getFlatIcon(A)//build_composite_icon(A)

			// If what we got back is actually a picture, draw it.
			if(istype(img, /icon))
				// Check if we're looking at a mob that's lying down
				if(istype(A, /mob/living) && A:lying)
					// If they are, apply that effect to their picture.
					img.BecomeLying()
				// Calculate where we are relative to the center of the photo
				var/xoff = (A.x - center.x) * 32 + center_offset
				var/yoff = (A.y - center.y) * 32 + center_offset
				if (istype(A,/atom/movable))
					xoff+=A:step_x
					yoff+=A:step_y
				res.Blend(img, blendMode2iconMode(A.blend_mode),  A.pixel_x + xoff, A.pixel_y + yoff)

	// Lastly, render any contained effects on top.
	for(var/turf/the_turf in turfs)
		// Calculate where we are relative to the center of the photo
		var/xoff = (the_turf.x - center.x) * 32 + center_offset
		var/yoff = (the_turf.y - center.y) * 32 + center_offset
		res.Blend(getFlatIcon(the_turf.loc), blendMode2iconMode(the_turf.blend_mode),xoff,yoff)
	return res
	
client/verb/gen_special_all()
	set category = "Debug"
	set name = "Generate Special Maps All Zooms"
	
	world << "*** Generating POWER ***"
	gen_special_mapall("wires", list(/obj/structure/cable, /obj/machinery/power))
	world << "*** Generating DISPOSAL ***"
	gen_special_mapall("disposals", list(/obj/structure/disposalpipe, /obj/structure/disposaloutlet, /obj/machinery/disposal))
	
// generate ALL MAP TILES
client/proc/gen_special_mapall(path, list/types)
	gen_special_map(path, types)
	for(var/i = 4; i >= 2; i--)
		gen_special_mapzooms(path, i)
	
// generate the zoomed out tiles
client/proc/gen_special_mapzooms(path, z)
	// figure out output grid size
	var/size = 32 / 2 ** (5 - z)

	for(var/x = 0; x < size; x++)
		world << "[x]"
		for(var/y = 0; y < size; y++)
			var/icon/res = icon('icons/effects/96x96.dmi', "")
			res.Scale(256, 256)
			var/icon/i = icon("./[path]/[z+1]/[round(x*2)]/[round(y*2)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=1,y=1)
			i = icon("./[path]/[z+1]/[round(x*2+1)]/[round(y*2)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=129,y=1)
			i = icon("./[path]/[z+1]/[round(x*2)]/[round(y*2+1)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=1,y=129)
			i = icon("./[path]/[z+1]/[round(x*2+1)]/[round(y*2+1)].png")
			i.Scale(128,128)
			res.Blend(i,ICON_OVERLAY,x=129,y=129)
			fcopy(res, "./[path]/[z]/[round(x)]/[round(y)].png")
	
// generate the 1:1 zoom tiles
client/proc/gen_special_map(path, list/types)
	for(var/x = 1; x <= 255; x += 8)
		world << "[x]"
		for(var/y = 1; y <= 255; y += 8)
			var/icon/I = map_get_special_icon(
				block(locate(max(1,x - 1), max(1,y - 1), 1),locate(min(255,x + 8), min(255,y + 8), 1)),
				locate(x + 3.5, y + 3.5, 1),
				types)
			fcopy(new/icon(I, "", SOUTH, 1, 0),
				"./[path]/5/[round(x/8)]/[round(y/8)].png")
	
client/proc/map_get_special_icon(list/turfs, turf/center, list/types)
	var/icon/res = icon('icons/effects/96x96.dmi', "")
	res.Scale(8*32, 8*32)

	var/atoms[] = list()
	for(var/turf/the_turf in turfs)
		// Add anything of the valid types
		for(var/atom/A in the_turf)
			for(var/T in types)
				if(istype(A, T))
					atoms.Add(A)
					break

	// Sort the atoms into their layers
	var/list/sorted = sort_atoms_by_layer(atoms)
	var/center_offset = 3 * 32
	for(var/i; i <= sorted.len; i++)
		var/atom/A = sorted[i]
		if(A)
			var/icon/img = getFlatIcon(A)//build_composite_icon(A)

			// If what we got back is actually a picture, draw it.
			if(istype(img, /icon))
				// Check if we're looking at a mob that's lying down
				if(istype(A, /mob/living) && A:lying)
					// If they are, apply that effect to their picture.
					img.BecomeLying()
				// Calculate where we are relative to the center of the photo
				var/xoff = (A.x - center.x) * 32 + center_offset
				var/yoff = (A.y - center.y) * 32 + center_offset
				if (istype(A,/atom/movable))
					xoff+=A:step_x
					yoff+=A:step_y
				res.Blend(img, blendMode2iconMode(A.blend_mode),  A.pixel_x + xoff, A.pixel_y + yoff)

	// Lastly, render any contained effects on top.
	for(var/turf/the_turf in turfs)
		// Calculate where we are relative to the center of the photo
		var/xoff = (the_turf.x - center.x) * 32 + center_offset
		var/yoff = (the_turf.y - center.y) * 32 + center_offset
		res.Blend(getFlatIcon(the_turf.loc), blendMode2iconMode(the_turf.blend_mode),xoff,yoff)
	return res