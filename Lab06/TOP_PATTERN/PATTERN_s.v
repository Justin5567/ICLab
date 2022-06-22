//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   File Name   : PATTERN.v
//   Module Name : PATTERN
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

`ifdef RTL_TOP
    `define CYCLE_TIME 60.0
`endif

`ifdef GATE_TOP
    `define CYCLE_TIME 55.0
`endif

module PATTERN (
    // Output signals
    clk,
    rst_n,
    in_valid,
    in_p,
    in_q,
    in_e,
    in_c,
    // Input signals
    out_valid,
    out_m
);

//================================================================
//      I/O PORTS
//================================================================
output reg             clk;
output reg           rst_n;
output reg        in_valid;
output reg [3:0]      in_p;
output reg [3:0]      in_q;
output reg [7:0]      in_e;
output reg [7:0]      in_c;
input            out_valid;
input [7:0]          out_m;

//======================================
//      PARAMETERS & VARIABLES
//======================================
real      CYCLE         = `CYCLE_TIME;
parameter CIPHER_CHANGE = 8;          // Indicate that it will send how many times of different cipher with the same in_p, in_q, in_e
parameter WIDTH         = 4;
parameter OUT_NUM       = 8;
parameter DELAY         = 10000;
integer   SEED          = 5200122;

integer       i;
integer       j;
integer       k;
integer    pat1;
integer    pat2;
integer    pat3;
integer    pat4;
integer exe_lat;
integer out_lat;
integer tot_lat;

//================================================================
//      WIRE & REGISTER  DECLARATION
//================================================================

//===================
//  Prime list
//===================
// Construct list of prime number
integer prime_list[0:999];
integer       prime_range; // maximum of prime list
integer        prime_flag; // show whether the number is prime or not
integer         prime_len; // how many prime number

//===================
//  IN_E Control
//===================
// Calculate the maximum of IN_E
// which should be greater than 1 and smaller than phi
integer               phi; // (p-1)(q-1)

// The gcd of IN_E and phi
// It need to ensure the gcd(e, phi) = 1
integer         gcd_e_phi;

integer          euclid_x;
integer          euclid_y;

//===================
//  Input data
//===================
integer              data_p;
integer              data_q;
integer              data_e;
reg [7:0]       cipher[0:7];
reg [7:0] gold_message[0:7];
reg [7:0] your_message[0:7];

integer              gold_d;
integer              gold_n;


//======================================
//              Clock
//======================================
initial clk = 0;
always #(CYCLE/2.0) clk = ~clk;


//======================================
//              MAIN
//======================================
initial exe_task;


//======================================
//              TASKS
//======================================
task exe_task; begin
    reset_task;
    prime_task;
	tot_lat = 0;
    for (pat1=0 ; pat1<=prime_len ; pat1=pat1+1) begin
        for (pat2=pat1+1 ; pat2<=prime_len ; pat2=pat2+1) begin
            phi_task;
            for(pat3=2 ; pat3<phi ; pat3=pat3+1) begin
                for(pat4=0 ; pat4<CIPHER_CHANGE ; pat4=pat4+1) begin
                    // Only consider the gcd between IN_E and phi is one
                    gcd(phi, pat3, gcd_e_phi);
                    if(gcd_e_phi == 1) begin
                        data_task;
                        wait_task;
                        check_task;
                        tot_lat = tot_lat + exe_lat;
                    end
                end
            end
            
        end
    end
    pass_task;
end endtask

task reset_task; begin
    force clk = 0;
    rst_n     = 1;
    in_valid  = 0;
    in_p      = 'dx;
    in_q      = 'dx;
    in_e      = 'dx;
    in_c      = 'dx;

    #(CYCLE/2.0) rst_n = 0;
    #(CYCLE/2.0) rst_n = 1;
    if ( out_valid !== 0 || out_m !== 0 ) begin
        $display("                                           `:::::`                                                       ");
        $display("                                          .+-----++                                                      ");
        $display("                .--.`                    o:------/o                                                      ");
        $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
        $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
        $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
        $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
        $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
        $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
        $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
        $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
        $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
        $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
        $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
        $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
        $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
        $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
        $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
        $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
        $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
        $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
        $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
        $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
        $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
        $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
        $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
        $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
        $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     after the reset signal is asserted");
        $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
        $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
        $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
        $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
        $display("                       `s--------------------------::::::::-----:o                                       ");
        $display("                       +:----------------------------------------y`                                      ");
        repeat(5) #(CYCLE);
        $finish;
    end
    #(CYCLE/2.0) release clk;
end endtask

task prime_task; begin
    // Calculate the maximum number of WIDTH
    prime_range = 1;
    for(i=0 ; i<WIDTH ; i=i+1)
        prime_range = 2*prime_range;

    //$display("%d", prime_range);

    // Construct the list of prime number
    prime_len = 0;
    for(i=2 ; i<prime_range ; i=i+1) begin
        prime_check(i, prime_flag);
        if(prime_flag == 1) begin
            prime_list[prime_len] = i;
            prime_len = prime_len + 1;
            //$display("%d %d", i, prime_len);
        end
    end
end endtask

task phi_task; begin
    phi = (prime_list[pat1]-1) * (prime_list[pat2]-1);
end endtask

task data_task; begin
    repeat( ({$random(SEED)} % 3 + 2) ) @(negedge clk);

    //********************
    // in_p, in_q, in_e
    //********************
    data_p = prime_list[pat1];
    data_q = prime_list[pat2];
    data_e = pat3;

    ext_euclid(0, data_e, phi, euclid_x, euclid_y);
    gold_d = euclid_x;
    gold_n = data_p*data_q;

    //$display("=========================");
    //$display("P   : %-2d, Q : %-2d", data_p, data_q);
    //$display("phi : %-2d, E : %-2d", phi, data_e);
    //$display("=========================");

    //********************
    // cipher & message
    //********************
    for(i=0 ; i<OUT_NUM ; i=i+1) begin
        // Message
        gold_message[i] = {$random(SEED)} % gold_n;

        // Cipher
        cipher[i] = (gold_message[i]*gold_message[i]) % gold_n;
        for(j=2 ; j<data_e ; j=j+1) begin
            cipher[i] = (cipher[i]*gold_message[i]) % gold_n;
        end
    end

    for(i=0 ; i<OUT_NUM ; i=i+1) begin
        in_valid = 1;
        if(i == 0) begin
            in_p = data_p;
            in_q = data_q;
            in_e = data_e;
        end
        else begin
            in_p = 'dx;
            in_q = 'dx;
            in_e = 'dx;
        end
        in_c = cipher[i];

        @(negedge clk);
    end
    in_valid  = 0;
    in_p      = 'dx;
    in_q      = 'dx;
    in_e      = 'dx;
    in_c      = 'dx;

end endtask

task wait_task; begin
    exe_lat = -1;
    while ( out_valid!==1 ) begin
        if ( out_m !== 0 ) begin
            $display("                                           `:::::`                                                       ");
            $display("                                          .+-----++                                                      ");
            $display("                .--.`                    o:------/o                                                      ");
            $display("              /+:--:o/                   //-------y.          -//:::-        `.`                         ");
            $display("            `/:------y:                  `o:--::::s/..``    `/:-----s-    .:/:::+:                       ");
            $display("            +:-------:y                `.-:+///::-::::://:-.o-------:o  `/:------s-                      ");
            $display("            y---------y-        ..--:::::------------------+/-------/+ `+:-------/s                      ");
            $display("           `s---------/s       +:/++/----------------------/+-------s.`o:--------/s                      ");
            $display("           .s----------y-      o-:----:---------------------/------o: +:---------o:                      ");
            $display("           `y----------:y      /:----:/-------/o+----------------:+- //----------y`                      ");
            $display("            y-----------o/ `.--+--/:-/+--------:+o--------------:o: :+----------/o                       ");
            $display("            s:----------:y/-::::::my-/:----------/---------------+:-o-----------y.                       ");
            $display("            -o----------s/-:hmmdy/o+/:---------------------------++o-----------/o                        ");
            $display("             s:--------/o--hMMMMMh---------:ho-------------------yo-----------:s`                        ");
            $display("             :o--------s/--hMMMMNs---------:hs------------------+s------------s-                         ");
            $display("              y:-------o+--oyhyo/-----------------------------:o+------------o-                          ");
            $display("              -o-------:y--/s--------------------------------/o:------------o/                           ");
            $display("               +/-------o+--++-----------:+/---------------:o/-------------+/                            ");
            $display("               `o:-------s:--/+:-------/o+-:------------::+d:-------------o/                             ");
            $display("                `o-------:s:---ohsoosyhh+----------:/+ooyhhh-------------o:                              ");
            $display("                 .o-------/d/--:h++ohy/---------:osyyyyhhyyd-----------:o-                               ");
            $display("                 .dy::/+syhhh+-::/::---------/osyyysyhhysssd+---------/o`                                ");
            $display("                  /shhyyyymhyys://-------:/oyyysyhyydysssssyho-------od:                                 ");
            $display("                    `:hhysymmhyhs/:://+osyyssssydyydyssssssssyyo+//+ymo`                                 ");
            $display("                      `+hyydyhdyyyyyyyyyyssssshhsshyssssssssssssyyyo:`                                   ");
            $display("                        -shdssyyyyyhhhhhyssssyyssshssssssssssssyy+.    Output signal should be 0         ");
            $display("                         `hysssyyyysssssssssssssssyssssssssssshh+                                        ");
            $display("                        :yysssssssssssssssssssssssssssssssssyhysh-     when the out_valid is pulled down ");
            $display("                      .yyhhdo++oosyyyyssssssssssssssssssssssyyssyh/                                      ");
            $display("                      .dhyh/--------/+oyyyssssssssssssssssssssssssy:   at %4d ps                         ", $time*1000);
            $display("                       .+h/-------------:/osyyysssssssssssssssyyh/.                                      ");
            $display("                        :+------------------::+oossyyyyyyyysso+/s-                                       ");
            $display("                       `s--------------------------::::::::-----:o                                       ");
            $display("                       +:----------------------------------------y`                                      ");
            repeat(5) @(negedge clk);
            $finish;
        end
        if (exe_lat == DELAY) begin
            $display("                                   ..--.                                ");
            $display("                                `:/:-:::/-                              ");
            $display("                                `/:-------o                             ");
            $display("                                /-------:o:                             ");
            $display("                                +-:////+s/::--..                        ");
            $display("    The execution latency      .o+/:::::----::::/:-.       at %-12d ps  ", $time*1000);
            $display("    is over %6d  cycles    `:::--:/++:----------::/:.                ", DELAY);
            $display("                            -+:--:++////-------------::/-               ");
            $display("                            .+---------------------------:/--::::::.`   ");
            $display("                          `.+-----------------------------:o/------::.  ");
            $display("                       .-::-----------------------------:--:o:-------:  ");
            $display("                     -:::--------:/yy------------------/y/--/o------/-  ");
            $display("                    /:-----------:+y+:://:--------------+y--:o//:://-   ");
            $display("                   //--------------:-:+ssoo+/------------s--/. ````     ");
            $display("                   o---------:/:------dNNNmds+:----------/-//           ");
            $display("                   s--------/o+:------yNNNNNd/+--+y:------/+            ");
            $display("                 .-y---------o:-------:+sso+/-:-:yy:------o`            ");
            $display("              `:oosh/--------++-----------------:--:------/.            ");
            $display("              +ssssyy--------:y:---------------------------/            ");
            $display("              +ssssyd/--------/s/-------------++-----------/`           ");
            $display("              `/yyssyso/:------:+o/::----:::/+//:----------+`           ");
            $display("             ./osyyyysssso/------:/++o+++///:-------------/:            ");
            $display("           -osssssssssssssso/---------------------------:/.             ");
            $display("         `/sssshyssssssssssss+:---------------------:/+ss               ");
            $display("        ./ssssyysssssssssssssso:--------------:::/+syyys+               ");
            $display("     `-+sssssyssssssssssssssssso-----::/++ooooossyyssyy:                ");
            $display("     -syssssyssssssssssssssssssso::+ossssssssssssyyyyyss+`              ");
            $display("     .hsyssyssssssssssssssssssssyssssssssssyhhhdhhsssyssso`             ");
            $display("     +/yyshsssssssssssssssssssysssssssssyhhyyyyssssshysssso             ");
            $display("    ./-:+hsssssssssssssssssssssyyyyyssssssssssssssssshsssss:`           ");
            $display("    /---:hsyysyssssssssssssssssssssssssssssssssssssssshssssy+           ");
            $display("    o----oyy:-:/+oyysssssssssssssssssssssssssssssssssshssssy+-          ");
            $display("    s-----++-------/+sysssssssssssssssssssssssssssssyssssyo:-:-         ");
            $display("    o/----s-----------:+syyssssssssssssssssssssssyso:--os:----/.        ");
            $display("    `o/--:o---------------:+ossyysssssssssssyyso+:------o:-----:        ");
            $display("      /+:/+---------------------:/++ooooo++/:------------s:---::        ");
            $display("       `/o+----------------------------------------------:o---+`        ");
            $display("         `+-----------------------------------------------o::+.         ");
            $display("          +-----------------------------------------------/o/`          ");
            $display("          ::----------------------------------------------:-            ");
            repeat(5) @(negedge clk);
            $finish; 
        end
        exe_lat = exe_lat + 1;
        @(negedge clk);
    end
end endtask

task check_task; begin
    out_lat = 0;
    i       = 0;
    while ( out_valid === 1 ) begin
        if (out_lat == OUT_NUM) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    Out cycles is more than %-1d                     /s:-----+s`     at %-12d ps   ", OUT_NUM, $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
            repeat(5) @(negedge clk);
            $finish;
        end
        
        if (i < OUT_NUM) begin
            your_message[i] = out_m;
            i=i+1;
        end
       
        out_lat = out_lat + 1;
        @(negedge clk);
    end
    
    if (out_lat < OUT_NUM) begin
        $display("                                                                                ");
        $display("                                                   ./+oo+/.                     ");
        $display("    Out cycles is less than %-1d                     /s:-----+s`     at %-12d ps   ", OUT_NUM, $time*1000);
        $display("                                                  y/-------:y                   ");
        $display("                                             `.-:/od+/------y`                  ");
        $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
        $display("                              -m+:::::::---------------------::o+.              ");
        $display("                             `hod-------------------------------:o+             ");
        $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
        $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
        $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
        $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
        $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
        $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
        $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
        $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
        $display("                 s:----------------/s+///------------------------------o`       ");
        $display("           ``..../s------------------::--------------------------------o        ");
        $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
        $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
        $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
        $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
        $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
        $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
        $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
        $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
        $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
        $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
        $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
        $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
        $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
        $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
        $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
        $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
        $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
        $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
        $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
        $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
        $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
        $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
        $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");
        repeat(5) @(negedge clk);
        $finish;
    end
    
    for (i=0 ; i<OUT_NUM ; i=i+1) begin
        if ( your_message[i] !== gold_message[i] ) begin
            $display("                                                                                ");
            $display("                                                   ./+oo+/.                     ");
            $display("    The Out_m is not correct!!!                   /s:-----+s`     at %-12d ps   ", $time*1000);
            $display("                                                  y/-------:y                   ");
            $display("                                             `.-:/od+/------y`                  ");
            $display("                               `:///+++ooooooo+//::::-----:/y+:`                ");
            $display("                              -m+:::::::---------------------::o+.              ");
            $display("                             `hod-------------------------------:o+             ");
            $display("                       ./++/:s/-o/--------------------------------/s///::.      ");
            $display("                      /s::-://--:--------------------------------:oo/::::o+     ");
            $display("                    -+ho++++//hh:-------------------------------:s:-------+/    ");
            $display("                  -s+shdh+::+hm+--------------------------------+/--------:s    ");
            $display("                 -s:hMMMMNy---+y/-------------------------------:---------//    ");
            $display("                 y:/NMMMMMN:---:s-/o:-------------------------------------+`    ");
            $display("                 h--sdmmdy/-------:hyssoo++:----------------------------:/`     ");
            $display("                 h---::::----------+oo+/::/+o:---------------------:+++s-`      ");
            $display("                 s:----------------/s+///------------------------------o`       ");
            $display("           ``..../s------------------::--------------------------------o        ");
            $display("       -/oyhyyyyyym:----------------://////:--------------------------:/        ");
            $display("      /dyssyyyssssyh:-------------/o+/::::/+o/------------------------+`        ");
            $display("    -+o/---:/oyyssshd/-----------+o:--------:oo---------------------:/.         ");
            $display("  `++--------:/sysssddy+:-------/+------------s/------------------://`          ");
            $display(" .s:---------:+ooyysyyddoo++os-:s-------------/y----------------:++.            ");
            $display(" s:------------/yyhssyshy:---/:o:-------------:dsoo++//:::::-::+syh`            ");
            $display("`h--------------shyssssyyms+oyo:--------------/hyyyyyyyyyyyysyhyyyy`            ");
            $display("`h--------------:yyssssyyhhyy+----------------+dyyyysssssssyyyhs+/.             ");
            $display(" s:--------------/yysssssyhy:-----------------shyyyyyhyyssssyyh.                ");
            $display(" .s---------------+sooosyyo------------------/yssssssyyyyssssyo                 ");
            $display("  /+-------------------:++------------------:ysssssssssssssssy-                 ");
            $display("  `s+--------------------------------------:syssssssssssssssyo                  ");
            $display("`+yhdo--------------------:/--------------:syssssssssssssssyy.                  ");
            $display("+yysyhh:-------------------+o------------/ysyssssssssssssssy/                   ");
            $display(" /hhysyds:------------------y-----------/+yyssssssssssssssyh`                   ");
            $display(" .h-+yysyds:---------------:s----------:--/yssssssssssssssym:                   ");
            $display(" y/---oyyyyhyo:-----------:o:-------------:ysssssssssyyyssyyd-                  ");
            $display("`h------+syyyyhhsoo+///+osh---------------:ysssyysyyyyysssssyd:                 ");
            $display("/s--------:+syyyyyyyyyyyyyyhso/:-------::+oyyyyhyyyysssssssyy+-                 ");
            $display("+s-----------:/osyyysssssssyyyyhyyyyyyyydhyyyyyyssssssssyys/`                   ");
            $display("+s---------------:/osyyyysssssssssssssssyyhyyssssssyyyyso/y`                    ");
            $display("/s--------------------:/+ossyyyyyyssssssssyyyyyyysso+:----:+                    ");
            $display(".h--------------------------:::/++oooooooo+++/:::----------o`                   ");

            $display("\033[0;32mInput Info :\033[1;0m");
            $display("\033[1;36m# %-5d\033[1;34m IN_P : %-3d, IN_Q : %-3d, IN_E : %-3d\033[1;0m", pat4, data_p, data_q, data_e);
            $display("\033[1;36m      \033[1;34m                 N : %-3d,    D : %-3d\033[1;0m", gold_n, gold_d);

            $display("\033[0;32mOriginal cipher :\033[1;0m");
            for ( i=0 ; i<OUT_NUM ; i=i+1 ) begin
                $write("%-3d ", cipher[i] );
            end
            $display("");

            $display("\033[0;32mYour message :\033[1;0m");
            for ( i=0 ; i<OUT_NUM ; i=i+1 ) begin
                if ( your_message[i] != gold_message[i] )
                    $write("\033[1;31m%-3d \033[1;0m", your_message[i] );
                else
                    $write("%-3d ", your_message[i] );
            end
            $display("");

            $display("\033[0;32mGolden message :\033[1;0m");
            for ( i=0 ; i<OUT_NUM ; i=i+1 ) begin
                if ( your_message[i] != gold_message[i] )
                    $write("\033[1;31m%-3d \033[1;0m", gold_message[i] );
                else
                    $write("%-3d ", gold_message[i] );
            end
            $display("");

            /*
            $display("\033[0;30m 1231123 \033[1;0m");
            $display("\033[0;31m 1231123 \033[1;0m");
            $display("\033[0;32m 1231123 \033[1;0m");
            $display("\033[0;33m 1231123 \033[1;0m");
            $display("\033[0;34m 1231123 \033[1;0m");
            $display("\033[0;35m 1231123 \033[1;0m");
            $display("\033[0;36m 1231123 \033[1;0m");
            $display("\033[0;37m 1231123 \033[1;0m");

            $display("\33[1m\033[0;30m 1231123 \033[1;0m");
            $display("\33[1m\033[0;31m 1231123 \033[1;0m");
            $display("\33[1m\033[0;32m 1231123 \033[1;0m");
            $display("\33[1m\033[0;33m 1231123 \033[1;0m");
            $display("\33[1m\033[0;34m 1231123 \033[1;0m");
            $display("\33[1m\033[0;35m 1231123 \033[1;0m");
            $display("\33[1m\033[0;36m 1231123 \033[1;0m");
            $display("\33[1m\033[0;37m 1231123 \033[1;0m");

            $display("\33[s\033[0;31m 1231123 \033[1;0m \33[u\033[0;33m 1231123 \033[1;0m ");
            */
            repeat(5) @(negedge clk);
            $finish;
        end
    end
    $display("\033[0;32mPATTERN PASS!!!\033[1;36m # %-5d\033[1;34m IN_P : %-2d, IN_Q : %-2d, IN_E : %-2d\033[1;0m", pat4, data_p, data_q, data_e);
	
    if(pat4 == CIPHER_CHANGE-1) $display("");
end endtask

task pass_task; begin
    $display("\033[1;33m                `oo+oy+`                            \033[1;35m Congratulation!!! \033[1;0m                                   ");
    $display("\033[1;33m               /h/----+y        `+++++:             \033[1;35m PASS This Lab........Maybe \033[1;0m                          ");
    $display("\033[1;33m             .y------:m/+ydoo+:y:---:+o             \033[1;35m Total Latency : %-10d\033[1;0m                                ", tot_lat);
    $display("\033[1;33m              o+------/y--::::::+oso+:/y                                                                                     ");
    $display("\033[1;33m              s/-----:/:----------:+ooy+-                                                                                    ");
    $display("\033[1;33m             /o----------------/yhyo/::/o+/:-.`                                                                              ");
    $display("\033[1;33m            `ys----------------:::--------:::+yyo+                                                                           ");
    $display("\033[1;33m            .d/:-------------------:--------/--/hos/                                                                         ");
    $display("\033[1;33m            y/-------------------::ds------:s:/-:sy-                                                                         ");
    $display("\033[1;33m           +y--------------------::os:-----:ssm/o+`                                                                          ");
    $display("\033[1;33m          `d:-----------------------:-----/+o++yNNmms                                                                        ");
    $display("\033[1;33m           /y-----------------------------------hMMMMN.                                                                      ");
    $display("\033[1;33m           o+---------------------://:----------:odmdy/+.                                                                    ");
    $display("\033[1;33m           o+---------------------::y:------------::+o-/h                                                                    ");
    $display("\033[1;33m           :y-----------------------+s:------------/h:-:d                                                                    ");
    $display("\033[1;33m           `m/-----------------------+y/---------:oy:--/y                                                                    ");
    $display("\033[1;33m            /h------------------------:os++/:::/+o/:--:h-                                                                    ");
    $display("\033[1;33m         `:+ym--------------------------://++++o/:---:h/                                                                     ");
    $display("\033[1;31m        `hhhhhoooo++oo+/:\033[1;33m--------------------:oo----\033[1;31m+dd+                                                 ");
    $display("\033[1;31m         shyyyhhhhhhhhhhhso/:\033[1;33m---------------:+/---\033[1;31m/ydyyhs:`                                              ");
    $display("\033[1;31m         .mhyyyyyyhhhdddhhhhhs+:\033[1;33m----------------\033[1;31m:sdmhyyyyyyo:                                            ");
    $display("\033[1;31m        `hhdhhyyyyhhhhhddddhyyyyyo++/:\033[1;33m--------\033[1;31m:odmyhmhhyyyyhy                                            ");
    $display("\033[1;31m        -dyyhhyyyyyyhdhyhhddhhyyyyyhhhs+/::\033[1;33m-\033[1;31m:ohdmhdhhhdmdhdmy:                                           ");
    $display("\033[1;31m         hhdhyyyyyyyyyddyyyyhdddhhyyyyyhhhyyhdhdyyhyys+ossyhssy:-`                                                           ");
    $display("\033[1;31m         `Ndyyyyyyyyyyymdyyyyyyyhddddhhhyhhhhhhhhy+/:\033[1;33m-------::/+o++++-`                                            ");
    $display("\033[1;31m          dyyyyyyyyyyyyhNyydyyyyyyyyyyhhhhyyhhy+/\033[1;33m------------------:/ooo:`                                         ");
    $display("\033[1;31m         :myyyyyyyyyyyyyNyhmhhhyyyyyhdhyyyhho/\033[1;33m-------------------------:+o/`                                       ");
    $display("\033[1;31m        /dyyyyyyyyyyyyyyddmmhyyyyyyhhyyyhh+:\033[1;33m-----------------------------:+s-                                      ");
    $display("\033[1;31m      +dyyyyyyyyyyyyyyydmyyyyyyyyyyyyyds:\033[1;33m---------------------------------:s+                                      ");
    $display("\033[1;31m      -ddhhyyyyyyyyyyyyyddyyyyyyyyyyyhd+\033[1;33m------------------------------------:oo              `-++o+:.`             ");
    $display("\033[1;31m       `/dhshdhyyyyyyyyyhdyyyyyyyyyydh:\033[1;33m---------------------------------------s/            -o/://:/+s             ");
    $display("\033[1;31m         os-:/oyhhhhyyyydhyyyyyyyyyds:\033[1;33m----------------------------------------:h:--.`      `y:------+os            ");
    $display("\033[1;33m         h+-----\033[1;31m:/+oosshdyyyyyyyyhds\033[1;33m-------------------------------------------+h//o+s+-.` :o-------s/y  ");
    $display("\033[1;33m         m:------------\033[1;31mdyyyyyyyyymo\033[1;33m--------------------------------------------oh----:://++oo------:s/d  ");
    $display("\033[1;33m        `N/-----------+\033[1;31mmyyyyyyyydo\033[1;33m---------------------------------------------sy---------:/s------+o/d  ");
    $display("\033[1;33m        .m-----------:d\033[1;31mhhyyyyyyd+\033[1;33m----------------------------------------------y+-----------+:-----oo/h  ");
    $display("\033[1;33m        +s-----------+N\033[1;31mhmyyyyhd/\033[1;33m----------------------------------------------:h:-----------::-----+o/m  ");
    $display("\033[1;33m        h/----------:d/\033[1;31mmmhyyhh:\033[1;33m-----------------------------------------------oo-------------------+o/h  ");
    $display("\033[1;33m       `y-----------so /\033[1;31mNhydh:\033[1;33m-----------------------------------------------/h:-------------------:soo  ");
    $display("\033[1;33m    `.:+o:---------+h   \033[1;31mmddhhh/:\033[1;33m---------------:/osssssoo+/::---------------+d+//++///::+++//::::::/y+`  ");
    $display("\033[1;33m   -s+/::/--------+d.   \033[1;31mohso+/+y/:\033[1;33m-----------:yo+/:-----:/oooo/:----------:+s//::-.....--:://////+/:`    ");
    $display("\033[1;33m   s/------------/y`           `/oo:--------:y/-------------:/oo+:------:/s:                                                 ");
    $display("\033[1;33m   o+:--------::++`              `:so/:-----s+-----------------:oy+:--:+s/``````                                             ");
    $display("\033[1;33m    :+o++///+oo/.                   .+o+::--os-------------------:oy+oo:`/o+++++o-                                           ");
    $display("\033[1;33m       .---.`                          -+oo/:yo:-------------------:oy-:h/:---:+oyo                                          ");
    $display("\033[1;33m                                          `:+omy/---------------------+h:----:y+//so                                         ");
    $display("\033[1;33m                                              `-ys:-------------------+s-----+s///om                                         ");
    $display("\033[1;33m                                                 -os+::---------------/y-----ho///om                                         ");
    $display("\033[1;33m                                                    -+oo//:-----------:h-----h+///+d                                         ");
    $display("\033[1;33m                                                       `-oyy+:---------s:----s/////y                                         ");
    $display("\033[1;33m                                                           `-/o+::-----:+----oo///+s                                         ");
    $display("\033[1;33m                                                               ./+o+::-------:y///s:                                         ");
    $display("\033[1;33m                                                                   ./+oo/-----oo/+h                                          ");
    $display("\033[1;33m                                                                       `://++++syo`                                          ");
    $display("\033[1;0m"); 
    repeat(5) @(negedge clk);
    $finish;
end endtask

//======================================
//      Calculation
//======================================
// Check whether the 'in' number is prime or not
// 0 ==> not prime
// 1 ==> prime
integer flag;
task prime_check;
    input  integer in;
    output integer out;
begin
    flag = 0;
    for(j=2 ; j*j<=in ; j=j+1) begin
        if((in%j) === 0 && flag === 0 ) begin
            flag = 1;
            out = 0;
        end
    end
    if(flag == 0) out = 1;
    if(in == 1) out = 0;
end endtask

// Find the greatest common divisor
integer gcd_q, gcd_r, b_temp, a_temp;
task gcd;
    input  integer a;
    input  integer b;
    output integer c;
begin
    a_temp = a;
    b_temp = b;
    // loop till remainder is 0
    while (b_temp > 0) begin
        gcd_q = a_temp / b_temp; // quotient
        gcd_r = a_temp - gcd_q * b_temp; // remainder
        a_temp = b_temp;
        b_temp = gcd_r;
    end
    c = a_temp;
end endtask

// Find ax + by = gcd(a,b)
integer euc_q, euc_r;
integer euc_a, euc_b;

integer cur_x, cur_y;
integer pre_x, pre_y;
integer tmp_x, tmp_y;
task ext_euclid;
    input  integer f;
    input  integer a;
    input  integer b;
    output integer x;
    output integer y;
begin
    euc_r = a%b;
    euc_q = (a-euc_r)/b;
    
    euc_a = b;
    euc_b = euc_r;
    
    cur_x = 1;
    cur_y = -euc_q;
    pre_x = 0;
    pre_y = 1;
    if(f == 1) begin
        $display("Rem  Quo  X    Y   ");
        $display("%-3d       1    0    ", a);
        $display("%-3d       0    1    ", b);
        $display("%-3d  %-3d  %-3d  %-3d", euc_r, euc_q, cur_x, cur_y);
    end
    while(euc_r !== 0) begin
        euc_r = euc_a%euc_b;
        euc_q = (euc_a-euc_r)/euc_b;
        
        euc_a = euc_b;
        euc_b = euc_r;
        
        tmp_x = cur_x;
        tmp_y = cur_y;
        cur_x = pre_x - cur_x*euc_q;
        cur_y = pre_y - cur_y*euc_q;
        pre_x = tmp_x;
        pre_y = tmp_y;
        if(f == 1) begin
            $display("%-3d  %-3d  %-3d  %-3d", euc_r, euc_q, cur_x, cur_y);
        end
    end
    if(pre_x < 0) x = pre_x + b;
    else          x = pre_x;
    y = pre_y;
end endtask

endmodule