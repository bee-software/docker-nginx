<?php
header( 'Content-Type: text/plain' );

foreach (getallheaders() as $name => $value) {
    echo "$name: $value\n";
}
?>
