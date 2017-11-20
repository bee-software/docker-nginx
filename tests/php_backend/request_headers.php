<?php
header( 'Content-Type: text/plain' );
echo 'Host: ' . $_SERVER['HTTP_HOST'] . "\n";
echo 'X-Real-IP: ' . $_SERVER['HTTP_X_REAL_IP'] . "\n";
echo 'X-Forwarded-For: ' . $_SERVER['HTTP_X_FORWARDED_FOR'] . "\n";
echo 'X-Forwarded-Proto: ' . $_SERVER['HTTP_X_FORWARDED_PROTO'] . "\n";
?>
