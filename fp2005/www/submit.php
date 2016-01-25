<?php
$pagetitle="Abstraktin lähetys";
include("top.php");
include("common.php");


$absdir = $rootdir . "abs/";

$sub_failed = 0;     // submission failed for some reason
$errmsg = "";
$error_stag = "<font color=\"$error_color\">";  // missing fields highlighted
$error_etag = "</font>";

$perm_checked = "checked";  // permission checked by default


// Replace nasty characters with spaces and
// trim those spaces (no space at beginning or end,
// and no multiple spaces in the middle of the string)
function trimstr($str) {
    $harmful = array("\n", "\r", "\t");
    return ereg_replace(" +", " ", str_replace($harmful, " ", trim($str)));
}

// Get file type with Unix 'file' command.
// Could/should be replaced with PECL Fileinfo
function get_filetype($path) {
    $out_string = `file -i $path`;
    ereg(': ([[:alnum:]/-]+)', $out_string, $regs);
    $filetype = $regs[1];
    if($filetype == '')
	$filetype = "unknown";
    return $filetype;
}

// Unzip $source (containing exactly one file) using $method (zip/gzip),
// return unzipped filename.
// $origname is the original name of the file in the archive
function unzip($method, $source, &$origname, &$failed, &$errmsg) {
    global $fatal_msg;
    $unzipped_file = '';

    if ($method == "zip") {  // Windows zip; see that there's only 1 file
	$filelist = `zipinfo -1 $source`;
	$files = explode("\n", $filelist);
	if ($files[0] == '') {  // empty zip (or some other error)
	    $failed = 1;
	} elseif ($files[1] != '') { // too many files
	    $failed = 1;
	    $errmsg = "Lähettämäsi zip-pakkaus sisältää useamman kuin yhden tiedoston.\n".
	     "Ole hyvä ja pakkaa zip-tiedostoon ainoastaan abstraktitiedosto.\n";
	}
    }

    if (!$failed) {  // let's unzip
	$unzipped_file = tempnam('', 'fpup') or exit($fatal_msg);
	if ($method == "zip") {
	    $origname = $files[0];
	    $cmd = "unzip -p $source > $unzipped_file";
	} else {
	    $origname = basename($origname, ".gz");    // The original name is stored in the gz-file,
	    $cmd = "gzip -cd $source > $unzipped_file";// but I don't know how to get it.
	}		

	if (system($cmd)) { // unzip failed
	    $failed = 1;
	    unlink($unzipped_file);
	}
    }

    if ($failed and !$errmsg) { // give a generic error msg
	$errmsg = "Lähettämäsi zip-tiedoston avaaminen ei onnistu. Yritä pakata se uudestaan.\n".
	     "Jos tämä ei auta, lähetä tiedosto uudelleen pakkaamattomana.\n";
    }

    return $unzipped_file;
}  // unzip()


// Get a unique id number for the submission
function get_id() {
    global $absdir;
    global $fatal_msg;
    $seqfile = $absdir . "seq"; // the last id is stored here
    if (file_exists($seqfile)) {
	$fp = fopen($seqfile, "r+") or exit($fatal_msg);
	flock($fp, LOCK_EX);
	$data = fread($fp, filesize($seqfile));
	$id = $data + 1;
	rewind($fp);
	ftruncate($fp, 0);
    } else {
	$fp = fopen($seqfile, "w") or exit($fatal_msg);
	flock($fp, LOCK_EX);
	$id = 1000;
    }
    fwrite($fp, $id);
    flock($fp, LOCK_UN);
    fclose($fp);
    return $id;
}

// The main code starts here

if ($_POST['submitted']) {           // The form has been submitted
    $authors = stripslashes(trimstr($_POST['authors']));
    if ($authors == '') {
	$sub_failed = 1;
	$stag[1] = $error_stag;
	$etag[1] = $error_etag;
    }
    
    $title = stripslashes(trimstr($_POST['title']));
    if ($title == '') {
	$sub_failed = 1;
	$stag[2] = $error_stag;
	$etag[2] = $error_etag;
    }

    $speaker = stripslashes(trimstr($_POST['speaker']));
    if ($speaker == '') {
	$sub_failed = 1;
	$stag[3] = $error_stag;
	$etag[3] = $error_etag;
    }

    $email = stripslashes(trimstr($_POST['email']));
    if ($email == '') {
	$sub_failed = 1;
	$stag[4] = $error_stag;
	$etag[4] = $error_etag;
    }

    $session = $_POST['session'];
    if (!$session) {
	$sub_failed = 1;
	$stag[5] = $error_stag;
	$etag[5] = $error_etag;
    } else $selected[$session] = "selected";

    $prestype = $_POST['prestype'];
    if ($prestype == 'poster')
	$pres_checked[1] = "checked";
    elseif ($prestype == 'oral')
	$pres_checked[2] = "checked";
    else {
	$sub_failed = 1;
	$stag[6] = $error_stag;
	$etag[6] = $error_etag;
    }

    if ($_POST['permit']) {
	$permit = 1;
	$perm_checked = "checked";
    } else {
	$permit = 0;
	$perm_checked = "";
    }

    if ($sub_failed) {
	$errmsg = "Et antanut kaikkia tietoja. Ole hyvä ja ".
	     "<font color=\"$error_color\">täytä puuttuvat kentät</font>.\n";
	if ($_FILES['absfile']['size'] > 0)  // abstract file was submitted
	    $errmsg.= "Samalla abstraktitiedosto täytyy lähettää uudestaan.\n";
    } else {  // all fields are ok, now the real works starts: process the abstract
	if ($_FILES['absfile']['size'] == 0) {  // no file
	    $sub_failed = 1;
	    $errmsg = "Abstraktitiedosto ei saapunut perille. Tarkista että tiedostonimi on oikein.\n" .
		 "Jos tiedoston koko on useita megatavuja, pakkaa se\n" .
		 "gzip- tai WinZip-ohjelmalla ja yritä uudestaan. Jos tämäkään\n" .
		 "ei auta, lähetä tiedosto sähköpostilla osoitteeseen\n" .
		 "<a href=\"mailto:fp2005@fyslab.hut.fi\">fp2005@fyslab.hut.fi</a>\n" .
		 "ja liitä mukaan alla olevan lomakkeen tiedot.\n";
	} else {  // there is a file
	    $origname = $_FILES['absfile']['name'];
	    $source = $_FILES['absfile']['tmp_name'];
	    $ftype = get_filetype($source);

	    if ($ftype == "application/x-zip") {
		$zipped = "zip";
		$source = unzip('zip', $source, $origname, $sub_failed, $errmsg);
	    } elseif ($ftype == "application/x-gzip") {
		$zipped = "gzip";
		$source = unzip('gzip', $source, $origname, $sub_failed, $errmsg);
	    }

	    if (!$sub_failed) {  // unzip ok, or not a zipped file
		if ($zipped)
		    $ftype = get_filetype($source);
		$suffix = array("application/postscript" => "eps",
				"application/pdf"        => "pdf",
				"application/msword"     => "doc",
				"application/rtf"        => "rtf",
				"text/rtf"               => "rtf");
		if (!$suffix[$ftype]) { // invalid format
		    $sub_failed = 1;
		    unlink($source);
		    $errmsg = "Tiedosto: " . htmlspecialchars($origname) . "<br>\n" .
			 "Formaatti: " . htmlspecialchars($ftype) ."</p>\n" .
			 "<p>Lähettämäsi tiedosto on väärässä muodossa. Sallitut formaatit\n" .
			 "ovat postscript, pdf, doc ja rtf. Yritä tallentaa tiedosto toisella\n".
			 "ohjelmalla tai käyttäen jotain toista sallittua formaattia.\n";
		} else {  // abstract ok
		    $id = get_id();
		    $dest = $absdir . $id . "." . $suffix[$ftype]; // save abstract as 1000.eps etc
		    if (file_exists($dest))  // something is terribly wrong; a race condition or
			exit ($fatal_msg);   // seq-file screwed
		    copy($source, $dest) or exit ($fatal_msg);
		    unlink($source);
		    chmod($dest, 0644);
		    $datafile = $absdir . $id . ".data";
		    $fp = fopen($datafile, "w") or exit ($fatal_msg);
		    fwrite($fp, "authors: ".$authors."\n");
		    fwrite($fp, "title: ".$title."\n");
		    fwrite($fp, "speaker: ".$speaker."\n");
		    fwrite($fp, "email: ".$email."\n");
		    fwrite($fp, "session: ".$session."\n");
		    fwrite($fp, "prestype: ".$prestype."\n");
		    fwrite($fp, "permit: ".$permit."\n");
		    fwrite($fp, "origname: ".$origname."\n");
		    fclose($fp);
		    chmod($datafile, 0644);
		}
	    }
	}
    }
}


// Output the page

$html_authors = htmlspecialchars($authors);
$html_title = htmlspecialchars($title);
$html_speaker = htmlspecialchars($speaker);
$html_email = htmlspecialchars($email);

if (empty($selected))  // select "--Valitse--" from the drop list
    $selected[0] = "selected";  



if (!$_POST['submitted'] or $sub_failed) {
    if ($sub_failed) {
	$stag[7] = $error_stag;  // The upload file must be selected every time
	$etag[7] = $error_etag;
	echo "<font color=\"$error_color\"><h2>Virhe! Abstraktin lähetys epäonnistui</h2>";
	echo "</font>\n<p>$errmsg</p>\n";
    } else {
	echo "<h2>Abstraktin lähetys</h2>\n";
	echo "<p>Täytä kaikki alla olevat kentät ohjeiden mukaan.\n";
	echo "Erikoismerkkien kohdalla voit käyttää LaTeX-notaatiota.</p>\n";
    }

    echo <<<END
<form action="$SCRIPT_NAME" method="post" enctype="multipart/form-data">
<input type="hidden" name="submitted" value="1">

<p>$stag[1]<b>[1] Tekijät</b>$etag[1] pilkulla erotettuina, esim.<br>
<tt>A. Author, T.T. Tekijä, W. Writer</tt><br>
<input type="text" name="authors" size="55" value="$html_authors">
</p>

<p>$stag[2]<b>[2] Otsikko</b>$etag[2] ei ALL CAPS -tyylillä kuten abstraktissa, 
esim.<br>
<tt>Enhanced $\gamma$-ray detector</tt><br>
<input type="text" name="title" size="55" value="$html_title">
</p>

<p>$stag[3]<b>[3] Esityksen pitäjä</b>$etag[3] esim.<br>
<tt>A. Author</tt><br>
<input type="text" name="speaker" size="30" value="$html_speaker">
</p>

<p>$stag[4]<b>[4] Yhteyshenkilön email-osoite</b>$etag[4]<br>
<input type="text" name="email" size="30" value="$html_email">
<p>

<p>$stag[5]<b>[5] Toivottu rinnakkaisistunto</b>$etag[5]<br>
<select name="session">
<option value="0" $selected[0]>-- Valitse --</option>

END;

    foreach ($sessions as $key => $value) {
	echo "<option value=\"", $key, "\" ", $selected[$key], ">", $value, "</option>\n";
    }

echo <<<END
</select>
</p>

<p>$stag[6]<b>[6] Toivottu esitystapa</b>$etag[6]<br>
<input type="radio" name="prestype" value="poster" $pres_checked[1]> posteri<br>
<input type="radio" name="prestype" value="oral" $pres_checked[2]> suullinen
</p>

<p>$stag[7]<b>[7] Abstraktitiedosto</b>$etag[7]<br>
Maksimikoko 10 megatavua, suuremmat tiedostot täytyy pakata Unixin gzip-
tai Windowsin WinZip-ohjelmalla. Tiedoston nimellä ei ole merkitystä.<br>
<input type="hidden" name="MAX_FILE_SIZE" value="10485760">
<input type="file" name="absfile" size="35">
</p>

<p><input type="checkbox" name="permit" $perm_checked>
Abstraktin saa julkaista <a href="ohjelma.php">ohjelmasivulla</a>.
</p>

<p>
<input type="submit" value="Lähetä tiedot"></p>
<p>Ellet saa napin painamisen jälkeen hyväksyvää vastausta,
tiedot eivät ole menneet perille!
</p>
</form>
END;
} else { // submission successful

    echo "<h2>Abstrakti vastaanotettu</h2>\n";
    echo "<p>Abstraktisi on onnistuneesti vastaanotettu alla olevin tiedoin.</p>\n";
    echo "<p>Tekijät: ", $html_authors, "<br>\n";
    echo "Otsikko: ", $html_title, "<br>\n";
    echo "Esittäjä: ", $html_speaker, "<br>\n";
    echo "Email: ", $html_email, "<br>\n";
    echo "Istunto: ", $sessions[$session], "<br>\n";
    echo "Tyyppi: ", ($prestype == "poster") ? "posteri" : "suullinen", "<br>\n";
    echo "Abstraktitiedosto: ", htmlspecialchars($origname), "<br>\n";
    echo "Julkaisu: ", $permit ? "webissä ja" : "vain", " abstraktikirjassa</p>\n";

    echo "<p>Lista hyväksytyistä abstrakteista julkaistaan\n";
    echo "<a href=\"ohjelma.php\">ohjelmasivulla</a> 25.2.2005 mennessä.\n";
    echo "Osallistujia ei informoida hyväksynnästä henkilökohtaisesti.</p>\n";

}

include("bottom.php");
?>
