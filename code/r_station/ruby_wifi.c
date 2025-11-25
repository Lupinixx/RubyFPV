/*
    Ruby Licence
    Copyright (c) 2020-2025 Petru Soroaga petrusoroaga@yahoo.com
    All rights reserved.
*/

#include "../base/base.h"
#include "../base/config.h"
#include "../base/hardware.h"
#include "../base/ctrl_settings.h"
#include <stdlib.h>
#include <string.h>

static int s_iCurrentWiFiMode = -1;

void ruby_wifi_apply_settings()
{
   ControllerSettings* pCS = get_ControllerSettings();
   if ( NULL == pCS )
      return;

   // If mode hasn't changed, do nothing
   if ( s_iCurrentWiFiMode == pCS->nWiFiMode )
      return;

   log_line("[WiFi] Applying WiFi settings. Mode: %d (0=disabled, 1=hotspot, 2=client)", pCS->nWiFiMode);
   
   // First, stop any existing WiFi services
   char szCommand[512];
   sprintf(szCommand, "%s/wifi_scripts/stop_wifi.sh", FOLDER_RUBY_TEMP);
   hw_execute_bash_command(szCommand, NULL);
   hardware_sleep_ms(500);

   s_iCurrentWiFiMode = pCS->nWiFiMode;

   if ( pCS->nWiFiMode == 0 )
   {
      log_line("[WiFi] WiFi is disabled");
      return;
   }

   if ( pCS->nWiFiMode == 1 )
   {
      // Hotspot mode
      log_line("[WiFi] Setting up WiFi hotspot. SSID: %s, Channel: %d", pCS->szWiFiSSID, pCS->nWiFiHotspotChannel);
      sprintf(szCommand, "%s/wifi_scripts/setup_wifi_hotspot.sh \"%s\" \"%s\" %d &", 
              FOLDER_RUBY_TEMP, pCS->szWiFiSSID, pCS->szWiFiPassword, pCS->nWiFiHotspotChannel);
      hw_execute_bash_command(szCommand, NULL);
   }
   else if ( pCS->nWiFiMode == 2 )
   {
      // Client mode
      log_line("[WiFi] Connecting to WiFi network. SSID: %s", pCS->szWiFiSSID);
      sprintf(szCommand, "%s/wifi_scripts/connect_wifi_client.sh \"%s\" \"%s\" &", 
              FOLDER_RUBY_TEMP, pCS->szWiFiSSID, pCS->szWiFiPassword);
      hw_execute_bash_command(szCommand, NULL);
   }
}

void ruby_wifi_init()
{
   log_line("[WiFi] Initializing WiFi management");
   s_iCurrentWiFiMode = -1;
   
   // Copy scripts to temp folder
   char szCommand[512];
   sprintf(szCommand, "mkdir -p %s/wifi_scripts", FOLDER_RUBY_TEMP);
   hw_execute_bash_command(szCommand, NULL);
   
   sprintf(szCommand, "cp -f %s/../r_utils/wifi_scripts/*.sh %s/wifi_scripts/ 2>/dev/null", FOLDER_CONFIG, FOLDER_RUBY_TEMP);
   hw_execute_bash_command(szCommand, NULL);
   
   sprintf(szCommand, "chmod +x %s/wifi_scripts/*.sh", FOLDER_RUBY_TEMP);
   hw_execute_bash_command(szCommand, NULL);
   
   ruby_wifi_apply_settings();
}

void ruby_wifi_uninit()
{
   log_line("[WiFi] Stopping WiFi services");
   char szCommand[512];
   sprintf(szCommand, "%s/wifi_scripts/stop_wifi.sh", FOLDER_RUBY_TEMP);
   hw_execute_bash_command(szCommand, NULL);
}
