<?php
$pagetitle = "Esitystiedoston lähetys";
include("top.php");
include("common.php");

$presroot = $rootdir . "pres/";

// Creates a directory tree recursively
function make_dirs($str_path, $mode = 0775)
{
    return is_dir($str_path) or
	(make_dirs(dirname($str_path), $mode) and mkdir($str_path, $mode));
}

// Read in the speaker data
$handle = fopen("$rootdir/speakers", "r") or exit($fatal_msg);
while (!feof($handle)) {
    $line = fgets($handle, 1024);
    if(ereg('([^:]*):([^:]*):([^:]*)', $line, $regs)) {
	$spkname[$regs[1]] = trim($regs[2]);
	$dirname[$regs[1]] = trim($regs[3]);
    }
}
fclose($handle);

if ($_POST['submitted']) {           // The form has been submitted
    if (!$dirname[$speaker])
	$errmsg = "<p><font color=\"$error_color\">Virhe! Valitse esittäjän nimi.</font></p>\n";
    else {  // process the file
	if ($_FILES['presfile']['size'] == 0) {
	    echo "<font color=\"$error_color\"><h2>Virhe! Lähetys epäonnistui</h2></font>\n";
	    echo "<p>Esitystiedosto ei saapunut perille. Tarkista että tiedostonimi on oikein.\n";
	    echo "Jos tiedoston koko on useita megatavuja, pakkaa se\n";
	    echo "gzip- tai WinZip-ohjelmalla ja yritä uudestaan. Jos tämäkään\n";
	    echo "ei auta, lähetä tiedosto sähköpostilla osoitteeseen\n";
	    echo "<a href=\"mailto:fp2005@fyslab.hut.fi\">fp2005@fyslab.hut.fi</a>.</p>\n";
	} else {  // there is a file; move it to $presdir
	    // Möllinen, Matti -> $presdir = $presroot/möllinen_matti/
	    $presdir = $presroot . $dirname[$speaker]. "/";
	    $origname = stripslashes($_FILES['presfile']['name']);
	    $destname = $origname;
	    if (file_exists($presdir . $destname)) { // if file.ext exists, try file.1.ext etc.
		$count = 1;
		if(ereg('(.*)(\.[^\.]+)', $destname, $regs)) {
		    $base = $regs[1];
		    $suffix = $regs[2];
		} else {
		    $base = $destname;
		    $suffix = "";
		}
		do {
		    $newname = $base . "." . $count++ . $suffix;
		} while (file_exists($presdir . $newname));
		rename($presdir . $destname, $presdir . $newname);
	    }
	    umask(0002);
	    make_dirs($presdir) or exit($fatal_msg);
	    umask(0113);
	    move_uploaded_file($_FILES['presfile']['tmp_name'], $presdir . $destname) or exit($fatal_msg);
	    echo "<h2>Tiedosto vastaanotettu</h2>\n";
	    echo "<p>Esittäjä: ", htmlspecialchars($spkname[$speaker]), "<br>\n";
	    echo "Tiedosto: ", htmlspecialchars($origname), "</p>\n";
	    echo "<p>Esitystiedostosi on onnistuneesti\n";
	    echo "vastaanotettu. Jos esitykseesi kuuluu useampia\n";
	    echo "tiedostoja, voit lähettää seuraavan tiedoston alla olevalla lomakkeella.\n";
	    echo "Voit myös myöhemmin lähettää päivitetyn version esityksestäsi.</p>\n";
	}
    }
}

echo <<<END
<h2>Esitystiedoston lähetys</h2>
$errmsg
<p>Kaikki suullisten esitysten tiedostot (Powerpoint, pdf jne.)
tulee lähettää järjestäjille etukäteen tällä
lomakkeella. Jos esitykseesi kuuluu useita tiedostoja, kuten animaatioita,
on suositeltavaa pakata ne yhteen zip- tai tar.gz-pakettiin. Voit myös
lähettää tiedostot yksi kerrallaan.
</p>
<p>Esitysten lähettämisen takarajaksi on asetettu 14.3.2005, jotta
järjestäjät ehtivät varmistaa tiedostojen toimivuuden luentosalien
tietokoneissa.
</p>
<form action="$SCRIPT_NAME" method="post" enctype="multipart/form-data">
<input type="hidden" name="submitted" value="1">

<p><b>Esittäjän nimi</b> ja esityksen tunnuskoodi<br>
<select name="speaker">
<option value="000">-- Valitse --</option>

END;

    foreach ($spkname as $key => $value) {
	echo "<option value=\"", $key, "\">", $value, "</option>\n";
    }

echo <<<END
</select>
</p>

<p><b>Esitystiedosto</b><br>
Maksimikoko 15 megatavua, suuremmat tiedostot täytyy pakata Unixin gzip-
tai Windowsin WinZip-ohjelmalla. Tiedoston nimellä ei ole merkitystä.<br>
<input type="hidden" name="MAX_FILE_SIZE" value="15728640">
<input type="file" name="presfile" size="30">
</p>

<p>
<input type="submit" value="Lähetä tiedosto">
</p>
<p>Ellet saa napin painamisen jälkeen hyväksyvää vastausta,
tiedosto ei ole mennyt perille!
</p>

</form>
END;

include("bottom.php");
?>
