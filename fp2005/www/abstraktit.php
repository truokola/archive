<?php
$pagetitle="Abstraktit";
include("top.php");
?>

<h2>Abstraktien valmistelu</h2>

<ul>
<li>Abstraktit tulee tehd‰ k‰ytt‰en alla olevia LaTeX- tai Word-mallipohjia.</li>
<li>Abstraktin maksimipituus on yksi sivu.</li>
<li>Jokaista esityst‰ kohden (suullinen tai posteri) tulee j‰tt‰‰ yksi abstrakti.</li>
<li>Hyv‰ksytyt abstraktit julkaistaan Fysiikan laboratorion raporttisarjassa
nimell‰ <em>Proceedings of the XXXIX Annual Conference of the Finnish Physical Society</em>,
sek‰ <a href="ohjelma.php">ohjelmasivulla</a>, mik‰li abstraktin l‰hett‰j‰lt‰ on saatu t‰h‰n
suostumus.</li>
</ul>



<h3>LaTeX-abstraktit</h3>
<p>K‰yt‰ alla olevia mallipohjia abstraktin tekoon:</p>
<ul>
<li><a href="pohjat/fp2005.tex">fp2005.tex</a></li>
<li><a href="pohjat/fp2005.sty">fp2005.sty</a></li>
<li><a href="pohjat/logo.eps">logo.eps</a></li>
</ul>
<p>LaTeX-abstrakti tulee k‰‰nt‰‰ eps-muotoon komennolla
<tt>dvips -E -o file.eps file.dvi</tt>. Mik‰li eps-tiedosto
on kooltaan useita megatavuja, se kannattaa pakata gzip-
tai WinZip-ohjelmalla.
</p>
<h3>Word-abstraktit</h3>
<p>Kopioi alla oleva mallipohja ja kirjoita abstrakti siin‰
olevien ohjeiden mukaan:</p>
<ul><li><a href="pohjat/fp2005.doc">fp2005.doc</a></li></ul>
<p>Abstraktin voi l‰hett‰‰ j‰rjest‰jille suoraan Word-muodossa,
mutta on suositeltavaa muuntaa se pdf-tiedostoksi.
T‰m‰ s‰‰st‰‰ tilaa, v‰hent‰‰ yhteensopivuusongelmia ja helpottaa
abstraktikirjan kokoamista.
</p>

<h2>Abstraktien l‰hett‰minen</h2>
<p>Kaikki abstraktit l‰hetet‰‰n www-lomakkeella eps-, Word- tai pdf-tiedostona,
mahdollisesti pakattuna.</p>
<blockquote>
<a href="submit.php"><img src="images/linkkinuoli.gif" alt="" border="0">L‰het‰ abstrakti</a>
</blockquote>
<p>Lista hyv‰ksytyist‰ esityksist‰ julkaistaan 
<a href="ohjelma.php">ohjelmasivulla</a> 25.2.2005 menness‰.
Osallistujia ei informoida hyv‰ksynn‰st‰ henkilˆkohtaisesti.
</p>

<h2>Esityksen pit‰minen</h2>
<h3>Posterit</h3>
<p>Posteritaulut ovat kooltaan noin 1,0 m (leveys) ◊ 1,2 m (korkeus).</p>

<h3>Suulliset esitykset</h3>
<p>Esitysmateriaalina voi k‰ytt‰‰ piirtoheitinkalvoja tai Powerpoint- tai pdf-tiedostoja.
Tiedostot tulee l‰hett‰‰ j‰rjest‰jille www-lomakkella etuk‰teen 14.3.2005 menness‰.</p>
<blockquote>
<a href="esitys.php"><img src="images/linkkinuoli.gif" alt="" border="0">L‰het‰ esitystiedosto</a>
</blockquote>
<p>Omia kannettavia ei voi kytke‰ projektoriin.
</p>

<?php
include("bottom.php");
?>
