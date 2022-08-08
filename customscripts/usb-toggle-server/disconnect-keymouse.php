<?php

if ($_GET["key"] === "8557C1674B6CFF0597E7FCDF262F6CD02103FE7BB204F92E56CC36E5D97F9918"){
   	shell_exec("sudo /usr/bin/usbip unbind -b 1-5");
   	shell_exec("sudo /usr/bin/usbip unbind -b 1-6");
   	shell_exec("xmodmap /home/js/.config/xremap");
} else{
	echo "Error";
}


?>
