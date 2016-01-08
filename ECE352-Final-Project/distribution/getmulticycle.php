<?php
    ini_set('display_errors', 'On');

    function hide_string ($key, $onechar, $zerochar) {
        $rv = "";
        
        for ($i = 0; $i < 32; $i++)     # Output fixed length.
        {
            if ($key & 1) { 
                $rv = $rv . $onechar;
            }
            else
            {
                $rv = $rv . $zerochar;
            }
            $key = $key >> 1;
        }
        return $rv;
    }
    
    function insert_text_before_and_after_file ($file, $before, $after) {
        $file_contents = file_get_contents("$file");
        $f = fopen ("$file.blahnew", "w");
        fwrite ($f, $before);
        fwrite ($f, $file_contents);
        fwrite ($f, $after);
        fclose ($f);
        rename ("$file.blahnew", "$file");
    }

    function insert_text_after_file ($file, $line) {
        $f = fopen ("$file", "a");
        fwrite ($f, $line);
        fclose ($f);
    }
    

#    echo getcwd();
#    exit (0);

    $fc = fopen ("counter.txt", "r+");
    $counter = 0;
    
    if (flock($fc, LOCK_EX)) {
        fscanf ($fc, "%u", $counter);
        $counter++;
        ftruncate ($fc, 0);
        fseek ($fc, 0);
        fprintf($fc, "%u", $counter);
        flock($fc, LOCK_UN);
    }
    else
    {
        #echo "Dying...";
        exit(1);
    }
    
    fclose($fc);


    mt_srand ($counter);
    $key = mt_rand();
#echo "Counter is $counter, key is $key\n";
#echo "test hide_string: " . hide_string($key, "\x2d", "\xad");
#echo "test hide_string: " . hide_string($key, " ", "\t");
    

    $folder = $counter;     # Change to $key
    mkdir ($folder);

    exec ("cp -r source/multicycle $folder/");
    exec ("chmod -R 777 $folder");       # Just in case...
    
    $comment_header = "// ---------------------------------------------------------------------\r\n";
    $comment_header = $comment_header . "// Copyright (c) 2007 by University of Toronto ECE 243 development team \r\n";
    $comment_header = $comment_header . "// ---------------------------------------------------------------------\r\n";
    $comment_header = $comment_header . "// " . hide_string($key, " ", "\t") . "\r\n";


    $qpf_footer = "PROJECT_COOKIE = \"" . sprintf("%08X", $key) . "\"\r\n";
    
    
    $tab_footer = hide_string($key, "\t", " ");
    $tab_footer = $tab_footer . "\r\n                   \r\n";


    insert_text_before_and_after_file ("$folder/multicycle/multicycle/FSM.v", $comment_header, $tab_footer);
    insert_text_before_and_after_file ("$folder/multicycle/multicycle/ALU.v", $comment_header, $tab_footer);
    insert_text_before_and_after_file ("$folder/multicycle/multicycle/multicycle.v", $comment_header, $tab_footer);

    insert_text_after_file("$folder/multicycle/multicycle/DualMem.v", $tab_footer);
    insert_text_after_file("$folder/multicycle/multicycle/multicycle.bsf", $tab_footer);
    insert_text_after_file("$folder/multicycle/multicycle/multicycle.qpf", $qpf_footer . $tab_footer);
    
    exec ("find $folder -exec touch -t 201503141509 {} \\;");
    $file_contents = shell_exec ("cd $folder ; zip -9rX - multicycle");
    exec ("rm -rf $folder");
    
    header('Content-type: application/zip');
    header('Content-Disposition: attachment; filename="multicycle.zip"');
    header('Expires: 0');
    header("Cache-Control: no-cache, must-revalidate");
    header('Content-Length: ' . strlen($file_contents));
    
    ob_clean();
    flush();
    print $file_contents;
    
    exit(0);
?>
