# ViSual Timetable
# SOLVED: TIME CONFLICT show SAT SUN problem
# SOLVED: When invisible, click_event should have no effect
# TODO: colgroup and constant column width for nice appearence
# TODO: click the added course to jump to the corresponding course table
# TODO: clicking the COMMON CORE/ search will work
# TODO: add a loading indicator

if not VST_LOADED
    VST_LOADED = true

    tt = [[],[],[],[],[],[],[]]     # Time table
    tc = [[],[],[],[],[],[],[]]     # Time conflict
    visible = true                  # visibility of the timetable

    go_to = (dept, ccode='', call_back='')->
        # An example: https://w5.ab.ust.hk/wcq/cgi-bin/1220/
        dept = dept.toUpperCase()
        semcode = window.location.href.match(/https:\/\/w5.ab.ust.hk\/wcq\/cgi-bin\/(\d+)\//)[1]
        url = "https://w5.ab.ust.hk/wcq/cgi-bin/#{semcode}/subject/#{dept}"
        $('div#classes').load url+' div#classes', ->
            document.title = dept + document.title[4..]
            $('tr.sectodd, tr.secteven').css({'cursor': 'pointer'}).unbind('click').click click_event
            if not ccode
                $(window).scrollTop(0)
            else
                $(window).scrollTop($("a[name=#{dept+ccode}]").offset().top-navHeight)

            if call_back
                call_back()

        return false

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
        if not visible
            return

        # console?.log "click event fired"
        # Reinitialize tc
        tc = [[],[],[],[],[],[],[]]

        # console?.log this

        timeslots = []
        
        course_name  = $(@).parents('.course').find('h2').text()
        course_code  = course_name[...course_name.indexOf('-')-1]
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
        
        return false   # return value
        #console?.log datetime

    delete_sect = (sect)->
        console?.log sect
        for dow in [0..6]
            temp_arr = []
            for l in tt[dow]
                if l.section isnt sect
                    temp_arr.push(l)
            tt[dow] = temp_arr[..]


        # this code remove the red rect when no more time conflicts
        no_time_conflict = true

        for dow in [0..6]
            for l_tc in tc[dow]
                for l_tt in tt[dow]
                    if check_time_conflict(l_tt, l_tc)
                        no_time_conflict = false

        if no_time_conflict
            tc = [[],[],[],[],[],[],[]]

        generate_table()
        return false   # return value

    generate_table = ->
        # 18 is 09:00, 37 is 18:30
        # the idiom [].concat(array...) flattens the array
        # ie. [[1,2,3],[4,5,6],[7,8,9]] -> [1,2,3,4,5,6,7,8,9]
        earliest_start_time = Math.min(18, (l.start_time for l in [].concat(tt...))..., (l.start_time for l in [].concat(tc...))...)
        latest_end_time     = Math.max(37, (l.end_time for l in [].concat(tt...))..., (l.end_time for l in [].concat(tc...))...)

        DAYS = ['Time','MON', 'TUE', 'WED', 'THU', 'FRI']
        SUN = tt[6].length isnt 0 or tc[6].length isnt 0
        SAT     = tt[5].length isnt 0 or tc[5].length isnt 0
        if SUN
            DAYS.push('SAT', 'SUN')
        else if SAT
            DAYS.push('SAT')

        # exclude the 'Time'
        range = DAYS.length - 1 
        # \u00A0 is &nbsp;
        empty_cell = '\u00A0'
        # delete previous content
        $('#container').empty()

        make_time_str = (hr)->
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

            return time_str

        DOMinate(
            [document.getElementById('container'),
                ['table',
                    ['thead'].concat((['th', header] for header in DAYS)),
                    ['tbody'].concat(['tr'].concat([['td', make_time_str(row)]], (['td', ['div', empty_cell, {'class':'outer'}], {'id': "c#{col}"}] for col in [1..range]), [{'id':"r#{row}"}]) for row in [earliest_start_time..latest_end_time])
                    {'id': 'vst', 'class': 'table table-bordered table-condensed'}
                ]
            ]
        )

        make_div_content = (l) ->
            c = "#{l.ccode}<br />#{l.section[...l.section.indexOf(' ')]}"
            return c

        for dow in [0...range]
            for l in tt[dow]
                $("<div id='#{l.section}' class='mydiv' style='background-color: #{l.color}; height: #{(l.end_time-l.start_time+1)*20+l.end_time-l.start_time}px'>#{make_div_content(l)}</div>")
                .appendTo("\#r#{l.start_time} \#c#{l.dow+1} div.outer")

        for dow in [0...range]
            for l in tc[dow]
                $("<div class='time-conflict' style='height: #{(l.end_time-l.start_time+1)*20+l.end_time-l.start_time}px'>\u00A0</div>")
                .appendTo("\#r#{l.start_time} \#c#{l.dow+1} div.outer")

        for dow in [0...range]
            for l in tt[dow]
                $("<div id='#{l.section}' class='topmost popup' style='height: #{(l.end_time-l.start_time+1)*20+l.end_time-l.start_time}px'><div class='popupdetail'><a href='#' class='goto'>DETAILS</a>\u00A0<a href='#' class='del'>DROP</a></div></div>")
                .data({'section': l.section, 'ccode': l.ccode})
                .appendTo("\#r#{l.start_time} \#c#{l.dow+1} div.outer")

        $('.del').click(->
            delete_sect($(@).parents('.popup').first().data('section'))
            return false
        )

        $('.goto').click(->
            go_to($(@).parents('.popup').first().data('ccode').split(' ')...)
            return false
        )

        # console?.log table_html
        # console?.log max_time
        # console?.log tt
        return false


    ###
        ENTRY POINT
    ###

    $(
        """
<style>
/*!
 * Bootstrap v2.2.2
 *
 * Copyright 2012 Twitter, Inc
 * Licensed under the Apache License v2.0
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Designed and built with all the love in the world @twitter by @mdo and @fat.
 */
.clearfix{*zoom:1;}.clearfix:before,.clearfix:after{display:table;content:"";line-height:0;}
.clearfix:after{clear:both;}
.hide-text{font:0/0 a;color:transparent;text-shadow:none;background-color:transparent;border:0;}
.input-block-level{display:block;width:100%;min-height:30px;-webkit-box-sizing:border-box;-moz-box-sizing:border-box;box-sizing:border-box;}
table{max-width:100%;background-color:transparent;border-collapse:collapse;border-spacing:0;}
.table{width:100%;margin-bottom:5px;}.table th,.table td{padding:8px;line-height:20px;text-align:left;vertical-align:top;border-top:1px solid #dddddd;}
.table th{font-weight:bold;}
.table thead th{vertical-align:bottom;}
.table caption+thead tr:first-child th,.table caption+thead tr:first-child td,.table colgroup+thead tr:first-child th,.table colgroup+thead tr:first-child td,.table thead:first-child tr:first-child th,.table thead:first-child tr:first-child td{border-top:0;}
.table tbody+tbody{border-top:2px solid #dddddd;}
.table .table{background-color:#ffffff;}
.table-condensed th,.table-condensed td{padding:4px 5px;}
.table-bordered{border:1px solid #dddddd;border-collapse:separate;*border-collapse:collapse;border-left:0;-webkit-border-radius:4px;-moz-border-radius:4px;border-radius:4px;}.table-bordered th,.table-bordered td{border-left:1px solid #dddddd;}
.table-bordered caption+thead tr:first-child th,.table-bordered caption+tbody tr:first-child th,.table-bordered caption+tbody tr:first-child td,.table-bordered colgroup+thead tr:first-child th,.table-bordered colgroup+tbody tr:first-child th,.table-bordered colgroup+tbody tr:first-child td,.table-bordered thead:first-child tr:first-child th,.table-bordered tbody:first-child tr:first-child th,.table-bordered tbody:first-child tr:first-child td{border-top:0;}
.table-bordered thead:first-child tr:first-child>th:first-child,.table-bordered tbody:first-child tr:first-child>td:first-child{-webkit-border-top-left-radius:4px;-moz-border-radius-topleft:4px;border-top-left-radius:4px;}
.table-bordered thead:first-child tr:first-child>th:last-child,.table-bordered tbody:first-child tr:first-child>td:last-child{-webkit-border-top-right-radius:4px;-moz-border-radius-topright:4px;border-top-right-radius:4px;}
.table-bordered thead:last-child tr:last-child>th:first-child,.table-bordered tbody:last-child tr:last-child>td:first-child,.table-bordered tfoot:last-child tr:last-child>td:first-child{-webkit-border-bottom-left-radius:4px;-moz-border-radius-bottomleft:4px;border-bottom-left-radius:4px;}
.table-bordered thead:last-child tr:last-child>th:last-child,.table-bordered tbody:last-child tr:last-child>td:last-child,.table-bordered tfoot:last-child tr:last-child>td:last-child{-webkit-border-bottom-right-radius:4px;-moz-border-radius-bottomright:4px;border-bottom-right-radius:4px;}
.table-bordered tfoot+tbody:last-child tr:last-child td:first-child{-webkit-border-bottom-left-radius:0;-moz-border-radius-bottomleft:0;border-bottom-left-radius:0;}
.table-bordered tfoot+tbody:last-child tr:last-child td:last-child{-webkit-border-bottom-right-radius:0;-moz-border-radius-bottomright:0;border-bottom-right-radius:0;}
.table-bordered caption+thead tr:first-child th:first-child,.table-bordered caption+tbody tr:first-child td:first-child,.table-bordered colgroup+thead tr:first-child th:first-child,.table-bordered colgroup+tbody tr:first-child td:first-child{-webkit-border-top-left-radius:4px;-moz-border-radius-topleft:4px;border-top-left-radius:4px;}
.table-bordered caption+thead tr:first-child th:last-child,.table-bordered caption+tbody tr:first-child td:last-child,.table-bordered colgroup+thead tr:first-child th:last-child,.table-bordered colgroup+tbody tr:first-child td:last-child{-webkit-border-top-right-radius:4px;-moz-border-radius-topright:4px;border-top-right-radius:4px;}
.table-striped tbody>tr:nth-child(odd)>td,.table-striped tbody>tr:nth-child(odd)>th{background-color:#f9f9f9;}
.table-hover tbody tr:hover td,.table-hover tbody tr:hover th{background-color:#f5f5f5;}
table td[class*="span"],table th[class*="span"],.row-fluid table td[class*="span"],.row-fluid table th[class*="span"]{display:table-cell;float:none;margin-left:0;}
.table td.span1,.table th.span1{float:none;width:44px;margin-left:0;}
.table td.span2,.table th.span2{float:none;width:124px;margin-left:0;}
.table td.span3,.table th.span3{float:none;width:204px;margin-left:0;}
.table td.span4,.table th.span4{float:none;width:284px;margin-left:0;}
.table td.span5,.table th.span5{float:none;width:364px;margin-left:0;}
.table td.span6,.table th.span6{float:none;width:444px;margin-left:0;}
.table td.span7,.table th.span7{float:none;width:524px;margin-left:0;}
.table td.span8,.table th.span8{float:none;width:604px;margin-left:0;}
.table td.span9,.table th.span9{float:none;width:684px;margin-left:0;}
.table td.span10,.table th.span10{float:none;width:764px;margin-left:0;}
.table td.span11,.table th.span11{float:none;width:844px;margin-left:0;}
.table td.span12,.table th.span12{float:none;width:924px;margin-left:0;}
.table tbody tr.success td{background-color:#dff0d8;}
.table tbody tr.error td{background-color:#f2dede;}
.table tbody tr.warning td{background-color:#fcf8e3;}
.table tbody tr.info td{background-color:#d9edf7;}
.table-hover tbody tr.success:hover td{background-color:#d0e9c6;}
.table-hover tbody tr.error:hover td{background-color:#ebcccc;}
.table-hover tbody tr.warning:hover td{background-color:#faf2cc;}
.table-hover tbody tr.info:hover td{background-color:#c4e3f3;}


table#vst td {
    /*border: 1px black solid;*/
    /*font-family:monospace;*/
    background-color: white;
    position: relative;
    padding: 0px;
    white-space: nowrap;
    height: 20px;
    width: 90px;
}
table#vst th {
    background-color: white;
}
.outer {
    position: relative;
    display: block;
}
.mydiv {
    width: 100%;
    position: absolute;
    left: 0;
    top: 0;
    z-index: 2;
    text-align: center;
}
.time-conflict {
    border: 2px red dotted;
    width: 100%;
    position: absolute;
    left: -2px;
    top:  -2px;
    z-index: 3;
}
.topmost {
    width: 100%;
    position: absolute;
    left: 0;
    top: 0;
    z-index: 4;
}
</style>
            <script src="https://raw.github.com/adius/DOMinate/master/src/dominate.essential.min.js" type="text/javascript"></script>
            <div id="myTimetable" style="background-color: #FFF; border: 2px solid #D4E0EC; padding: 0px; position: fixed; right: 5px; bottom: 5px; z-index: 1000; ">
                <div id="container">
                    <h1>How to use:</h1>
                    Click the section of the course to add that section to time table.<br><br>
                    To delete the section from your time table,<br>
                    click DROP when your mouse is over the section on the timetable.<br><br>
                    Clicking hyperlinks other than the department names<br>
                    Or clicking the BACK/NEXT/REFRESH button of the browser<br>
                    will erase your work
                </div>
                <a href="#" id="toggle_show">show/hide</a>
                <br>
                <a href="#" id="load_confirmed">load confirmed enrollment</a>
            </div>
        """
    ).appendTo('body')

    $('#toggle_show').click ->
        $('#container').toggle(120)
        visible = not visible
        return false

    $('#load_confirmed').click ->
        if not visible
            return false
        alert """
            This would clear your current timetable
            And it may take some time to finish
            Works only for the current semester
            Login required
        """

        tt = [[],[],[],[],[],[],[]]
        tc = [[],[],[],[],[],[],[]]

        semcode = window.location.href.match(/https:\/\/w5.ab.ust.hk\/wcq\/cgi-bin\/(\d+)\//)[1]
        $('div#classes').load "https://w5.ab.ust.hk/cgi-bin/std_cgi.sh/WService=broker_si_p/prg/sita_enrol_ta_intf.r?p_stdt_id=&p_reg_acad_yr=20#{semcode[..1]}&p_reg_semes_cde=#{semcode[2]}", ->
            console.log $('div#classes').html()
            xml_code = $('div#classes').html().match(/id="xml" value="(.*?)"/)?[1]
            console.log xml_code
            if not xml_code
                alert "ERROR: Cannot fetch your confirmed enrollment for this semester\nPlease add the classes manually"
                return false
            courses = xml_code.match(/&lt;course&gt;(.*?)&lt;\/course&gt;/g)
            if not courses
                courses = xml_code.match(/<course>(.*?)<\/course>/g)
                if not courses
                    alert "ERROR: Cannot fetch your confirmed enrollment for this semester\nPlease add the classes manually"
                    return false                    

            for i in [0...courses.length]
                course_code = courses[i].match(/&lt;courseCode&gt;(.*?)&lt;\/courseCode&gt;/)?[1]
                if not course_code
                    course_code = courses[i].match(/<courseCode>(.*?)<\/courseCode>/)?[1]
                L  = courses[i].match(/&lt;L&gt;(.*?)&lt;\/L&gt;/)?[1]
                if not L
                    L  = courses[i].match(/<L>(.*?)<\/L>/)?[1]
                T  = courses[i].match(/&lt;T&gt;(.*?)&lt;\/T&gt;/)?[1]
                if not T
                    T  = courses[i].match(/<T>(.*?)<\/T>/)?[1]
                LA = courses[i].match(/&lt;LA&gt;(.*?)&lt;\/LA&gt;/)?[1]
                if not LA
                    LA = courses[i].match(/<LA>(.*?)<\/LA>/)?[1]
                dept = course_code[..3]
                numeric_code = course_code[4..]
                
                my_call_back = ((L, T, LA, dept, numeric_code) ->
                    ->
                        $("a[name=#{dept+numeric_code}]").parents('.course').find('.sections').find('tr').each ->
                            first_cell_content = $(@).find('td').first().text()
                            # console.log first_cell_content
                            first_cell_content = first_cell_content[...first_cell_content.indexOf(' ')]
                            if first_cell_content is L or first_cell_content is T or first_cell_content is LA
                                $(@).click()

                )(L, T, LA, dept, numeric_code)

                go_to(dept, numeric_code, my_call_back)

                # console.log course_code, L, T, LA

        return false

    highlight = ->
        this.style.border = "2px solid yellow"
    dehighlight = ->
        this.style.border = "0"

    $('tr.sectodd, tr.secteven').css({'cursor': 'pointer'}).click(click_event)#.hover(highlight, dehighlight)

    bring_to_top = ->
        this.style.zIndex = 9999
    bring_to_back = ->
        this.style.zIndex = 500

    $('div#navigator').hover(bring_to_top, bring_to_back).find('div.depts').find('a').click ->
        $('div#classes').load @href+' div#classes', =>
            document.title = @href[-4..] + document.title[4..]
            $('tr.sectodd, tr.secteven').css({'cursor': 'pointer'}).unbind('click').click click_event
            # window.location.hash = '#'
            $(window).scrollTop(0)
            return false
        return false

else
    alert "VST already loaded"
