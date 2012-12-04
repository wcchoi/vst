# ViSual Timetable
# SOLVED: TIME CONFLICT show SAT SUN problem
# SOLVED: When invisible, click_event should have no effect
# TODO: colgroup and constant column width for nice appearence
# TODO: click the added course to jump to the corresponding course table
# TODO: clicking the COMMON CORE/ search will work
# TODO: add a loading indicator

if not VST_LOADED

    tt = [[],[],[],[],[],[],[]]     # Time table
    tc = [[],[],[],[],[],[],[]]     # Time conflict
    visable = true                  # visibility of the timetable

    go_to = (dept, ccode='')->
        # An example: https://w5.ab.ust.hk/wcq/cgi-bin/1220/
        dept = dept.toUpperCase()
        semcode = window.location.href.match(/https:\/\/w5.ab.ust.hk\/wcq\/cgi-bin\/(\d+)\//)[1]
        url = "https://w5.ab.ust.hk/wcq/cgi-bin/#{semcode}/subject/#{dept}"
        $('div#classes').load url + ' div#classes', ->
            document.title = dept + document.title[4..]
            $('tr.sectodd, tr.secteven').unbind('click').click click_event
            if not ccode
                $('body').scrollTop(0)
            else
                $(window).scrollTop($("a[name=#{dept+ccode}]").offset().top-navHeight)
        false

    hsv_to_rgb = (h, s, v)->
        h_i = Math.floor(h*6)
        f = h*6 - h_i
        p = v * (1 - s)
        q = v * (1 - f*s)
        t = v * (1 - (1 - f) * s)
        [r, g, b] = [v, t, p] if h_i is 0
        [r, g, b] = [q, v, p] if h_i is 1
        [r, g, b] = [p, v, t] if h_i is 2
        [r, g, b] = [p, q, v] if h_i is 3
        [r, g, b] = [t, p, v] if h_i is 4
        [r, g, b] = [v, p, q] if h_i is 5
        rgb = [Math.floor(r*256), Math.floor(g*256), Math.floor(b*256)]

    get_random_color = ->
        ###
            based on http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
        ###
        golden_ratio_conjugate = 0.618033988749895
        h = Math.random()
        h += golden_ratio_conjugate
        h %= 1
        rgb = hsv_to_rgb(h, 0.3, 0.99)
        color = "#"+rgb[0].toString(16)+rgb[1].toString(16)+rgb[2].toString(16)

    check_time_conflict = (t1, t2) ->
        if (t2.start_time <= t1.start_time <= t2.end_time) or 
           (t2.start_time <= t1.end_time   <= t2.end_time) or 
           (t1.start_time <= t2.start_time <= t1.end_time) or 
           (t1.start_time <= t2.end_time   <= t1.end_time)
            return true
        else
            return false

    process_datetime = (dt, room, section, ccode, color) ->
        if dt is 'TBA'
            return []
        
        result = []
        mapping = {'Mo':0, 'Tu':1, 'We':2, 'Th':3, 'Fr':4, 'Sa':5, 'Su':6}
        
        parts = dt.split(' ')
        parts.splice(2, 1)
        
        # ST stands for Start Time
        # ET stands for End Time
        STapm = parts[1][-2..]
        [SThh, STmm] = parts[1][...-2].split(':')
        if STapm is 'PM' and SThh isnt '12'
            start_time = (parseInt(SThh, 10) + 12) * 2
        else
            start_time = (parseInt(SThh, 10)) * 2
        
        if STmm is '30'
            start_time += 1
        
        
        ETapm = parts[2][-2..]
        [EThh, ETmm] = parts[2][...-2].split(':')
        if ETapm is 'PM' and EThh isnt '12'
            end_time = (parseInt(EThh, 10) + 12) * 2
        else
            end_time = (parseInt(EThh, 10)) * 2
        
        if ETmm is '50'
            end_time += 1
        
        
        evens = (x for x in [0...parts[0].length] by 2)
        for i in evens
            dow = mapping[parts[0][i..i+1]]
            result.push({dow, start_time, end_time, room, section, ccode, color})
            # console?.log dow, start_time, end_time
        
        return result
        
    click_event = ->
        if not visable
            return

        console?.log "click event fired"
        # Reinitialize tc
        tc = [[],[],[],[],[],[],[]]

        console?.log this

        timeslots = []
        
        course_name = $(@).parents('.course').find('h2').text()
        course_code = course_name[...course_name.indexOf('-')-1]
        course_color = get_random_color()


        $first_row = $(@)
        if not $first_row.is('.newsect')
            $first_row = $first_row.prevAll('.newsect:first')
        
        sect = $first_row.find('td:first').text()
        
        $rows = [$first_row]
        $rest = $first_row.nextUntil('.newsect')
        if $rest.length
            $rows = $rows.concat($rest.clone().prepend("<td>#{sect}</td>"))
        
        for $row in $rows
            td_arr = $row.find('td').map(-> $(@).text()).get()
            
            [section, datetime, room] = td_arr
            
            # console?.log section, datetime, room
            
            if datetime.match(/\d{2}\-\w{3}\-\d{4} \- \d{2}\-\w{3}\-\d{4}/)
                datetime = datetime[25..]   #get rid of the date
            
            timeslots = timeslots.concat(process_datetime(datetime, room, section, course_code, course_color))
        

        no_time_conflict = true

        for lesson in timeslots
            for l in tt[lesson.dow]
                if check_time_conflict(l, lesson)
                    no_time_conflict = false

        if not no_time_conflict
            for lesson in timeslots
                tc[lesson.dow].push(lesson)
        else
            for lesson in timeslots
                tt[lesson.dow].push(lesson)

        generate_table()
        
        false   # return value
        #console?.log datetime

    delete_sect = (sect)->
        console?.log sect
        for dow in [0..6]
            temp_arr = []
            for l in tt[dow]
                if l.section isnt sect
                    temp_arr.push(l)
            tt[dow] = temp_arr[..]

        generate_table()
        false   # return value

    generate_table = ->
        # 18 is 9am
        max_time = 18
        min_time = 18

        # <<<< Find the range which should be rendered
        for dow in [0..6]
            for l in tt[dow]
                if l.end_time > max_time
                    max_time = l.end_time
                if l.start_time < min_time
                    min_time = l.start_time
        for dow in [0..6]
            for l in tc[dow]
                if l.end_time > max_time
                    max_time = l.end_time
                if l.start_time < min_time
                    min_time = l.start_time
        # Find the range which should be rendered >>>>
        

        # <<<< the table and its style
        tbl = document.createElement('table')
        tbl.id = 'vst'
        tbl.style.border = 0
        tbl.style.borderCollapse = 'collapse'
        # the table and its style >>>>


        # <<<< table header's content
        DAYS = ['Time','MON', 'TUE', 'WED', 'THU', 'FRI']
        SAT_SUN = tt[6].length isnt 0 or tc[6].length isnt 0
        SAT     = tt[5].length isnt 0 or tc[5].length isnt 0
        if SAT_SUN
            DAYS.push('SAT', 'SUN')
        else if SAT
            DAYS.push('SAT')
        # table header's content >>>>

        # <<<< create thead elems
        tbl_thead = document.createElement('thead')
        for D in DAYS
            td = document.createElement('th')
            td_textnode = document.createTextNode(D)
            td.appendChild(td_textnode)
            tbl_thead.appendChild(td)
        tbl.appendChild(tbl_thead)
        # create thead elems >>>>

        # one row
        for row in [min_time..max_time]
        
            hr = Math.floor(row/2)
            # pad zero
            if hr <= 9
                hr = '0'+hr.toString()
            else
                hr = hr.toString()
            
            min = row%2
            if min is 0
                time_str = hr + ':00-' + hr + ':20'
            else
                time_str = hr + ':30-' + hr + ':50'
        

            tbl_row = document.createElement('tr')

            time_td = document.createElement('td')
            time_td_text_node = document.createTextNode(time_str)
            time_td.appendChild(time_td_text_node)
            tbl_row.appendChild(time_td)

            for col in [0..6]
            
                if col is 5
                    if not (SAT_SUN or SAT)
                        continue
                if col is 6
                    if not SAT_SUN
                        continue
                        
                done = false

                cell = 
                    content: '---'
                    js: ''
                    css:
                        bgc: ''
                        border:
                            Top   : ''
                            Left  : ''
                            Right : ''
                            Bottom: ''

                for l in tt[col]

                    if done
                        break

                    if l.start_time is row
                        cell.css.border.Top = '1px solid black'
                        cell.content = l.ccode
                        done = true
                    else if (l.start_time + 1) is row
                        if (l.start_time+1) is l.end_time
                            cell.css.border.Bottom = '1px solid black'
                            cell.content = l.section[...l.section.indexOf(' ')]
                        else
                            cell.content = l.section[...l.section.indexOf(' ')]

                        done = true
                    else if (row > l.start_time and row < l.end_time)
                        done = true
                        cell.content = ''
                    else if l.end_time is row
                        cell.css.border.Bottom = '1px solid black'
                        cell.content = ''
                        done = true

                    if done
                        cell.js = ((sect)->
                            ->
                                delete_sect(sect)
                                false
                        )(l.section)
                        cell.css.bgc = l.color
                        cell.css.border.Left = cell.css.border.Right = '1px solid black'

                # <<<< Override the CSS in case of TIME CONFLICT
                for l in tc[col]
                    if row is l.start_time
                        cell.css.border.Top = '2px dashed red'
                        cell.css.border.Left = cell.css.border.Right = '2px dashed red'
                    else if row > l.start_time and row < l.end_time
                        cell.css.border.Left = cell.css.border.Right = '2px dashed red'
                    else if row is l.end_time
                        cell.css.border.Left = cell.css.border.Right = '2px dashed red'
                        cell.css.border.Bottom = '2px dashed red'
                # Override the CSS in case of TIME CONFLICT >>>>

                cell_td = document.createElement('td')
                cell_td_text_node = document.createTextNode(cell.content)
                cell_td.appendChild(cell_td_text_node)
                
                if cell.css.bgc
                    cell_td.style.backgroundColor = cell.css.bgc

                for own k, v of cell.css.border
                    if cell.css.border[k]
                        cell_td.style['border'+k] = v

                if cell.js
                    $(cell_td).click cell.js

                tbl_row.appendChild(cell_td)
            
            tbl.appendChild(tbl_row)

        
        $('#container').empty().append(tbl)

        # console?.log table_html
        # console?.log max_time
        # console?.log tt
        false   # return value


    ###
        ENTRY POINT
    ###

    $(
        """
            <div id="myTimetable" style="background-color: #FFF; border: 2px solid #D4E0EC; padding: 0px; position: fixed; right: 0; bottom: 0; z-index: 1000; ">
                <div id="container"></div>
                <a href="#" id="toggle_show">show/hide</a>
            </div>
        """
    ).appendTo('body')

    $('#toggle_show').click ->
        $('#container').toggle()
        visable = not visable
        false

    highlight = ->
        this.style.border = "2px solid yellow"
    dehighlight = ->
        this.style.border = "0"

    $('tr.sectodd, tr.secteven').click(click_event)#.hover(highlight, dehighlight)

    bring_to_top = ->
        this.style.zIndex = 9999
    bring_to_back = ->
        this.style.zIndex = 500

    $('div#navigator').hover(bring_to_top, bring_to_back).find('div.depts').find('a').click ->
        $('div#classes').load @href+' div#classes', =>
            document.title = @href[-4..] + document.title[4..]
            $('tr.sectodd, tr.secteven').unbind('click').click click_event
            # window.location.hash = '#'
            $('body').scrollTop(0)
            false
        false #return value

    VST_LOADED = true

else
    alert "VST already loaded"