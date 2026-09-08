# Comrade API

Comrade supports **deep linking** for external apps, browsers, or command-line tools to interact with the app. Right now it only supports opening screen but in future we are planning to support integration with third party apps.

### Future plans -

- [x] Navigate to any screen with specified parameters.
- [ ] Execute actions like start session, block apps by invoking intent from third party apps like Tasker with parameters.
- [ ] Broadcast event to third party apps when focus session starts/ends.
- [ ] Broadcast event to third party apps when bedtime routine starts/ends.
- [ ] Overall broadcast to third party apps when some special events occurs.



### Endpoints or Hosts -

## 1. OPEN
>  [!Tip]
> ### _com.comrade.android://open_
> Navigates user to a specific screen with the provided parameters.
          
  * ### `/home`  
    - **Description:** Opens the home screen on the specified tab.  
    - **Example:** `com.comrade.android://open/home?tab=1`
    - **Parameters:**  
      - `tab` (Optional)  
          - `0` → Dashboard (Default)  
          - `1` → Statistics  
          - `2` → Notifications  
          - `3` → Bedtime  
          
  * ### `/focus`  
    - **Description:** Opens the focus screen on the specified tab.  
    - **Example:** `com.comrade.android://open/focus?tab=1`
    - **Parameters:**  
      - `tab` (Optional)  
          - `0` → Focus (Default)  
          - `1` → Timeline  
          
  * ### `/activeSession`  
    - **Description:** Opens the active session screen.  
    - **Example:** `com.comrade.android://open/activeSession`
  
  * ### `/appDashboard`  
    - **Description:** Opens the app's dashboard screen with the specified parameters.  
    - **Example:** `com.comrade.android://open/appDashboard?package=com.instagram.android&usageType=1&day=2025-06-28`
    - **Parameters:**  
      - `package` (Required)
          - Package name of the targeted app  
          
      - `usageType` (Optional)  
          - `0` → Screen usage (Default)  
          - `1` → Network usage  
          
      - `day` (Optional)  
          - Targeted day's date formatted as string (yyyy-mm-dd)
          - Date today (Default)  
         
      
  * ### `/notifications`  
    - **Description:** Opens the batched notifications screen on the specified tab.  
    - **Example:** `com.comrade.android://open/notifications?tab=1`
    - **Parameters:**  
      - `tab` (Optional)  
          - `0` → Notifications (Default)  
          - `1` → Timeline
    
          
  * ### `/parentalControls`  
    - **Description:** Opens the parental and invincible mode controls screen.  
    - **Example:** `com.comrade.android://open/parentalControls`
  
  * ### `/restrictionGroups`  
    - **Description:** Opens the restriction groups screen.  
    - **Example:** `com.comrade.android://open/restrictionGroups`

  * ### `/shortsBlocking`  
    - **Description:** Opens the shorts blocking screen.  
    - **Example:** `com.comrade.android://open/shortsBlocking`
   
  * ### `/websitesBlocking`  
    - **Description:** Opens the websites blocking screen.  
    - **Example:** `com.comrade.android://open/websitesBlocking`
          
  * ### `/settings`  
    - **Description:** Opens the settings screen on the specified tab.  
    - **Example:** `com.comrade.android://open/settings?tab=1`
    - **Parameters:**  
      - `tab` (Optional)  
          - `0` → General (Default)  
          - `1` → Database  
          - `2` → About  
  
  * ### `/changeLogs`  
    - **Description:** Opens the latest changelogs screen.  
    - **Example:** `com.comrade.android://open/changeLogs`


---
## 2. EXECUTE (Under development)
> [!Tip]
> ### _com.comrade.android://execute_
> Navigate user to specific screen and perform some action automatically.

---

## Testing 

Please ensure Comrade is installed before testing. To test deep links manually, you can use the following methods:  

### **Using ADB Command:**  
```sh
adb shell am start -a android.intent.action.VIEW -d "com.comrade.android://open/home?tab=1"
```

### **Using the Browser:**  
Create an HTML file with following content. Open the created HTML file in a browser and click on `Launch`
```HTML
<a href="intent://open/home?tab=1#Intent;scheme=com.comrade.android;package=com.comrade.android;end">Launch</a>

```
