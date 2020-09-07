{-
  This is my xmonad configuration file.
  There are many like it, but this one is mine.

  If you want to customize this file, the easiest workflow goes
  something like this:
    1. Make a small change.
    2. Hit "super-q", which recompiles and restarts xmonad
    3. If there is an error, undo your change and hit "super-q" again to
       get to a stable place again.
    4. Repeat

  Author:     David Brewer
  Repository: https://github.com/davidbrewer/xmonad-ubuntu-conf
-}

import           Control.Monad                     (liftM2)
import           System.Exit
import           System.IO
import           XMonad
import           XMonad.Actions.CopyWindow
import           XMonad.Actions.CycleRecentWS
import           XMonad.Actions.FindEmptyWorkspace
import qualified XMonad.Actions.FlexibleResize     as Flex
import           XMonad.Actions.FloatSnap
import           XMonad.Actions.GroupNavigation
import           XMonad.Actions.Plane
import           XMonad.Actions.SimpleDate
import           XMonad.Actions.WindowGo
import           XMonad.Hooks.DynamicLog
import           XMonad.Hooks.EwmhDesktops         hiding (fullscreenEventHook)
import qualified XMonad.Hooks.EwmhDesktops         as E
import           XMonad.Hooks.ManageDocks
import           XMonad.Hooks.SetWMName
import           XMonad.Hooks.UrgencyHook
import           XMonad.Layout.Circle
import           XMonad.Layout.Fullscreen
import           XMonad.Layout.Grid
import           XMonad.Layout.IM
import           XMonad.Layout.NoBorders
import           XMonad.Layout.PerWorkspace        (onWorkspace)
import           XMonad.Layout.ResizableTile
import           XMonad.Layout.Tabbed
import           XMonad.Layout.ThreeColumns
import           XMonad.Util.EZConfig
import           XMonad.Util.Run
-- import XMonad.Hooks.ICCCMFocus  -- deprecated
import qualified Data.Map                          as M
import           Data.Ratio                        ((%))
import           Graphics.X11.ExtraTypes.XF86
import qualified XMonad.StackSet                   as W

{-
  Xmonad configuration variables. These settings control some of the
  simpler parts of xmonad's behavior and are straightforward to tweak.
-}

myModMask            = mod1Mask       -- changes the mod key to "alt"
mySecModMask         = mod4Mask       -- provides the start key as alternative modifier
myFocusedBorderColor = "#ff0000"      -- color of focused border
myNormalBorderColor  = "#cccccc"      -- color of inactive border
myBorderWidth        = 1              -- width of border around windows
myTerminal           = "terminator"   -- which terminal software to use
myIMRosterTitle      = "Buddy List"   -- title of roster on IM workspace
                                      -- use "Buddy List" for Pidgin, but
                                      -- "Contact List" for Empathy
myScreenshot = "screenshot"
mySelectScreenshot = "select-screenshot"

{-
  Xmobar configuration variables. These settings control the appearance
  of text which xmonad is sending to xmobar via the DynamicLog hook.
-}

myTitleColor     = "#eeeeee"  -- color of window title
myTitleLength    = 80         -- truncate window title to this length
myCurrentWSColor = "#e6744c"  -- color of active workspace
myVisibleWSColor = "#c185a7"  -- color of inactive workspace
myUrgentWSColor  = "#cc0000"  -- color of workspace with 'urgent' window
myBackGroundWSColor = "#000000" -- color of background of workspaces
myAltBackGroundWSColor = "#220011" -- color of background of workspaces
myCopiedWSColor     = "#77ee99"  -- Light blue for copied windows
myCurrentWSLeft  = "["        -- wrap active workspace with these
myCurrentWSRight = "]"
myVisibleWSLeft  = "("        -- wrap inactive workspace with these
myVisibleWSRight = ")"
myUrgentWSLeft   = "{"         -- wrap urgent workspace with these
myUrgentWSRight  = "}"
myLauncher       = "$(yeganesh -x -- -fn 'monospace-8' -nb '#000000' -nf '#FFFFFF' -sb '#7C7C7C' -sf '#CEFFAC')"
myFileLauncher   = "menu-d"

myStartupHook    = do
      setWMName "LG3D"
      windows $ W.greedyView startupWorkspace
      ewmhDesktopsStartup
      spawn "~/.xmonad/startup-hook"

myEventHook = ewmhDesktopsEventHook <+> E.fullscreenEventHook <+> fullscreenEventHook

myManageHook = manageHook def
      <+> composeAll myManagementHooks
      <+> manageDocks
myFocusFollowsMouse :: Bool
myFocusFollowsMouse = True

{-
  Workspace configuration. Here you can change the names of your
  workspaces. Note that they are organized in a grid corresponding
  to the layout of the number pad.

  I would recommend sticking with relatively brief workspace names
  because they are displayed in the xmobar status bar, where space
  can get tight. Also, the workspace labels are referred to elsewhere
  in the configuration file, so when you change a label you will have
  to find places which refer to it and make a change there as well.

  This central organizational concept of this configuration is that
  the workspaces correspond to keys on the number pad, and that they
  are organized in a grid which also matches the layout of the number pad.
  So, I don't recommend changing the number of workspaces unless you are
  prepared to delve into the workspace navigation keybindings section
  as well.
-}

myWorkspaces =
  [
    "7:Chat",  "8:Dbg", "9:Pix",
    "4:Docs",  "5:Dev", "6:Web",
    "1:Term",  "2:Hub", "3:Mail",
    "0:VM",    "-:Extr1", "=:Extr2"
  ]

startupWorkspace = "5:Dev"  -- which workspace do you want to be on after launch?

{-
  Layout configuration. In this section we identify which xmonad
  layouts we want to use. I have defined a list of default
  layouts which are applied on every workspace, as well as
  special layouts which get applied to specific workspaces.

  Note that all layouts are wrapped within "avoidStruts". What this does
  is make the layouts avoid the status bar area at the top of the screen.
  Without this, they would overlap the bar. You can toggle this behavior
  by hitting "super-b" (bound to ToggleStruts in the keyboard bindings
  in the next section).
-}

-- Define group of default layouts used on most screens, in the
-- order they will appear.
-- "smartBorders" modifier makes it so the borders on windows only
-- appear if there is more than one visible window.
-- "avoidStruts" modifier makes it so that the layout provides
-- space for the status bar at the top of the screen.
defaultLayouts = avoidStruts(
  -- ResizableTall layout has a large master window on the left,
  -- and remaining windows tile on the right. By default each area
  -- takes up half the screen, but you can resize using "super-h" and
  -- "super-l".
  ResizableTall 1 (3/100) (1/2) []

  -- Mirrored variation of ResizableTall. In this layout, the large
  -- master window is at the top, and remaining windows tile at the
  -- bottom of the screen. Can be resized as described above.
  ||| Mirror (ResizableTall 1 (3/100) (1/2) [])

  -- Full layout makes every window full screen. When you toggle the
  -- active window, it will bring the active window to the front.

  -- ThreeColMid layout puts the large master window in the center
  -- of the screen. As configured below, by default it takes of 3/4 of
  -- the available space. Remaining windows tile to both the left and
  -- right of the master window. You can resize using "super-h" and
  -- "super-l".
  -- ||| ThreeColMid 1 (3/100) (3/4)

  -- Circle layout places the master window in the center of the screen.
  -- Remaining windows appear in a circle around it
  -- ||| Circle

  -- Grid layout tries to equally distribute windows in the available
  -- space, increasing the number of columns and rows as necessary.
  -- Master window is at top left.
  ||| Grid
  ||| tabbed shrinkText tabConfig
  ||| noBorders Full
  )
  ||| noBorders (fullscreenFull Full)

tabConfig = def {
  activeBorderColor = "#7C7C7C",
  activeTextColor = "#CEFFAC",
  activeColor = "#000000",
  inactiveBorderColor = "#7C7C7C",
  inactiveTextColor= "#EEEEEE",
  inactiveColor = "#111111"
                         }
-- Here we define some layouts which will be assigned to specific
-- workspaces based on the functionality of that workspace.

-- The chat layout uses the "IM" layout. We have a roster which takes
-- up 1/8 of the screen vertically, and the remaining space contains
-- chat windows which are tiled using the grid layout. The roster is
-- identified using the myIMRosterTitle variable, and by default is
-- configured for Pidgin, so if you're using something else you
-- will want to modify that variable.
chatLayout = avoidStruts(withIM (1%7) (Title myIMRosterTitle) Grid)

-- The GIMP layout uses the ThreeColMid layout. The traditional GIMP
-- floating panels approach is a bit of a challenge to handle with xmonad;
-- I find the best solution is to make the image you are working on the
-- master area, and then use this ThreeColMid layout to make the panels
-- tile to the left and right of the image. If you use GIMP 2.8, you
-- can use single-window mode and avoid this issue.
gimpLayout = smartBorders(avoidStruts(ThreeColMid 1 (3/100) (3/4)))

-- Here we combine our default layouts with our specific, workspace-locked
-- layouts.
myLayouts =
  onWorkspace "7:Chat" chatLayout
  $ onWorkspace "9:Pix" gimpLayout
  $ defaultLayouts

myMouseBindings (XConfig {XMonad.modMask = modMask}) = M.fromList $
  [
    -- mod-button1, Set the window to floating mode and move by dragging
    ((modMask, button1),
     (\w -> focus w >> mouseMoveWindow w >> afterDrag (snapMagicMove (Just 50) (Just 50) w)))

    -- mod-button1, Set the window to floating mode and resize by dragging
    , ((modMask .|. shiftMask, button1),
       (\w -> focus w >> Flex.mouseResizeWindow w >> afterDrag (snapMagicResize [L,R,U,D] (Just 50) (Just 50) w)))

    -- mod-button2, Raise the window to the top of the stack
    , ((modMask, button2),
       (\w -> focus w >> windows W.swapMaster))

    -- mod-button3, Set the window to floating mode and resize by dragging
    , ((modMask, button3),
       (\w -> focus w >> mouseResizeWindow w >> afterDrag (snapMagicResize [L,R,U,D] (Just 50) (Just 50) w)))

    -- you may also bind events to the mouse scroll wheel (button4 and button5)
  ]


{-
  Custom keybindings. In this section we define a list of relatively
  straightforward keybindings. This would be the clearest place to
  add your own keybindings, or change the keys we have defined
  for certain functions.

  It can be difficult to find a good list of keycodes for use
  in xmonad. I have found this page useful -- just look
  for entries beginning with "xK":

  http://xmonad.org/xmonad-docs/xmonad/doc-index-X.html

  Note that in the example below, the last three entries refer
  to nonstandard keys which do not have names assigned by
  xmonad. That's because they are the volume and mute keys
  on my laptop, a Lenovo W520.

  If you have special keys on your keyboard which you
  want to bind to specific actions, you can use the "xev"
  command-line tool to determine the code for a specific key.
  Launch the command, then type the key in question and watch
  the output.
-}

myKeys conf@(XConfig { XMonad.modMask = myModMask}) = M.fromList $
  [
    ((myModMask, xK_b), sendMessage ToggleStruts)
    , ((myModMask, xK_a), sendMessage MirrorShrink)
    , ((myModMask, xK_z), sendMessage MirrorExpand)
    , ((myModMask, xK_p), spawn myLauncher)
    , ((myModMask, xK_u), focusUrgent)
    , ((0, 0x1008FF12), spawn "amixer -q set Master toggle")
    , ((0, 0x1008FF11), spawn "amixer -q set Master 5%-")
    , ((0, 0x1008FF13), spawn "amixer -q set Master 5%+")
    , ((myModMask, xK_F6), spawn "amixer set Speaker toggle")
    , ((myModMask, xK_F7), spawn "my-player volume 0.1-")
    , ((myModMask, xK_F8), spawn "my-player volume 0.1+")
    , ((myModMask, xK_bracketleft), spawn "my-player previous")
    , ((myModMask, xK_bracketright), spawn "my-player next")
    , ((myModMask, xK_backslash), spawn "my-player play-pause")
    , ((myModMask .|. shiftMask, xK_backslash), spawn "my-player stop")
    , ((myModMask .|. shiftMask, xK_bracketleft), spawn "my-player position 10-")
    , ((myModMask .|. shiftMask, xK_bracketright), spawn "my-player position 10+")
    , ((myModMask, xK_apostrophe), spawn "my-player-next") -- go to next player in mpris
    , ((myModMask .|. shiftMask, xK_apostrophe), spawn "my-player-prev") -- go to prev player in mpris

    -- Start a terminal.  Terminal to start is specified by myTerminal variable.
    , ((myModMask .|. shiftMask, xK_Return),
     spawn $ XMonad.terminal conf)
    {-
    -- Lock the screen using command specified by myScreensaver.
    , ((myModMask .|. controlMask, xK_l),
      spawn myScreensaver)
    -}
    -- Spawn the launcher using command specified by myLauncher.
    -- Use this to launch programs without a key binding.
    , ((myModMask, xK_p),
      spawn myLauncher)

    -- Take a selective screenshot using the command specified by mySelectScreenshot.
    , ((myModMask, xK_s),
      spawn myScreenshot)

    -- Take a selective screenshot using the command specified by mySelectScreenshot.
    , ((myModMask .|. shiftMask, xK_s),
      spawn mySelectScreenshot)

    -- Take a full screenshot using the command specified by myScreenshot.
    , ((myModMask .|. controlMask .|. shiftMask, xK_p),
      spawn myScreenshot)

    -- Spawn a file launcher using menu-d [xdg-open, fasd and dmenu]
    , ((myModMask .|. shiftMask, xK_p),
      spawn myFileLauncher)

    -- Show date not very useful
    -- , ((myModMask,               xK_d     ), date)

    -- View, shift to and view, and cast away to, empty Workspaces
      , ((myModMask,                xK_n    ), viewEmptyWorkspace)
      , ((myModMask .|. shiftMask,  xK_n    ), tagToEmptyWorkspace)
      , ((myModMask .|. controlMask, xK_n    ), sendToEmptyWorkspace)

    -- Rotate through terminator windows
      , ((mySecModMask, xK_t), nextMatch Forward  (className =? "Terminator"))
      , ((mySecModMask .|. shiftMask, xK_t), nextMatch Backward (className =? "Terminator"))

    -- Rotate through similar windows
      -- , ((mySecModMask , xK_j), nextMatchWithThis2 Forward  className isOnAnyVisibleWS)
      -- , ((mySecModMask , xK_k), nextMatchWithThis2 Backward className isOnAnyVisibleWS)

      , ((mySecModMask , xK_j), nextMatchWithThis Forward  className)
      , ((mySecModMask , xK_k), nextMatchWithThis Backward className)
{-
    -- Mute volume.
    , ((0, xF86XK_AudioMute),
      spawn "amixer -q set Master toggle")

    -- Decrease volume.
    , ((0, xF86XK_AudioLowerVolume),
      spawn "amixer -q set Master 5%-")

    -- Increase volume.
    , ((0, xF86XK_AudioRaiseVolume),
      spawn "amixer -q set Master 5%+")

    -- Mute volume.
    , ((myModMask .|. controlMask, xK_m),
      spawn "amixer -q set Master toggle")

    -- Decrease volume.
    , ((myModMask .|. controlMask, xK_j),
      spawn "amixer -q set Master 5%-")

    -- Increase volume.
    , ((myModMask .|. controlMask, xK_k),
      spawn "amixer -q set Master 5%+")

    -- Audio previous.
    , ((0, 0x1008FF16),
      spawn "")

    -- Play/pause.
    , ((0, 0x1008FF14),
      spawn "")

    -- Audio next.
    , ((0, 0x1008FF17),
      spawn "")
-} -- I feel my defaults were working fine before.
    -- Eject CD tray.
    , ((0, 0x1008FF2C),
      spawn "eject -T")

  --------------------------------------------------------------------
  -- "Standard" xmonad key bindings
  --

  -- Close focused window.
    , ((myModMask .|. shiftMask, xK_c),
      kill1)
    -- Make focused window always visible
    , ((mySecModMask, xK_v ), windows copyToAll) -- Make focused window always visible

    -- Make focused window Not always visible
    , ((mySecModMask .|. shiftMask , xK_v ), killAllOtherCopies)

    -- Cycle through the available layout algorithms.
    , ((myModMask, xK_space),
      sendMessage NextLayout)

    --  Reset the layouts on the current workspace to default.
    , ((myModMask .|. shiftMask, xK_space),
      setLayout $ XMonad.layoutHook conf)

    -- Resize viewed windows to the correct size.
    , ((mySecModMask, xK_n),
      refresh)

    -- Cycle through most recent workspaces.
    , ((mySecModMask, xK_grave),
      cycleRecentWS [xK_Super_L] xK_Tab xK_grave)

    -- Cycle through most recent workspaces.
    , ((mySecModMask, xK_Tab),
      cycleRecentWS [xK_Super_L] xK_Tab xK_grave)

    -- Move focus to the next window.
    , ((myModMask, xK_Tab),
      windows W.focusDown)

    -- Move focus to the previous window.
    , ((myModMask .|. shiftMask , xK_Tab),
      windows W.focusUp)

    -- Move focus to the next window.
    , ((myModMask, xK_j),
      windows W.focusDown)

    -- Move focus to the previous window.
    , ((myModMask, xK_k),
      windows W.focusUp  )

    -- Move focus to the master window.
    , ((myModMask, xK_m),
      windows W.focusMaster  )

    -- Swap the focused window and the master window.
    , ((myModMask, xK_Return),
      windows W.swapMaster)

    , ((myModMask .|. shiftMask , xK_m),
      windows W.swapMaster)

    -- Swap the focused window with the next window.
    , ((myModMask .|. shiftMask, xK_j),
      windows W.swapDown  )

    -- Swap the focused window with the previous window.
    , ((myModMask .|. shiftMask, xK_k),
      windows W.swapUp    )

    -- Shrink the master area.
    , ((myModMask, xK_h),
      sendMessage Shrink)

    -- Expand the master area.
    , ((myModMask, xK_l),
      sendMessage Expand)

    -- Push window back into tiling.
    , ((myModMask, xK_t),
      withFocused $ windows . W.sink)

    -- Increment the number of windows in the master area.
    , ((myModMask, xK_comma),
      sendMessage (IncMasterN 1))

    -- Decrement the number of windows in the master area.
    , ((myModMask, xK_period),
      sendMessage (IncMasterN (-1)))

  -- Toggle the status bar gap.
  -- TODO: update this binding with avoidStruts, ((myModMask, xK_b),

  -- Quit xmonad.
    , ((myModMask .|. shiftMask, xK_q),
      io (exitWith ExitSuccess))

    -- Restart xmonad.
    , ((myModMask, xK_q),
      restart "xmonad" True)

    -- For Transcribe me Alt+0
    , ((mySecModMask, xK_0),
      spawn "xdotool key alt+0")
  ]
  ++ workSpaceKeys
    -- tried to chain properties for group navigation
    -- where
    --   nextMatchWithThis2 :: (Eq a , Eq b) => XMonad.Actions.GroupNavigation.Direction -> Query a -> Query b -> X ()
    --   nextMatchWithThis2 dir qryA qryB = withFocused $ \win -> do
    --     propA <- runQuery qryA win
    --     propB <- runQuery qryB win
    --     nextMatch dir ((qryA =? propA) <&&> (qryB =? propB))




{-
  Management hooks. You can use management hooks to enforce certain
  behaviors when specific programs or windows are launched. This is
  useful if you want certain windows to not be managed by xmonad,
  or sent to a specific workspace, or otherwise handled in a special
  way.

  Each entry within the list of hooks defines a way to identify a
  window (before the arrow), and then how that window should be treated
  (after the arrow).

  To figure out to identify your window, you will need to use a
  command-line tool called "xprop". When you run xprop, your cursor
  will temporarily change to crosshairs; click on the window you
  want to identify. In the output that is printed in your terminal,
  look for a couple of things:
    - WM_CLASS(STRING): values in this list of strings can be compared
      to "className" to match windows.
    - WM_NAME(STRING): this value can be compared to "resource" to match
      windows.

  The className values tend to be generic, and might match any window or
  dialog owned by a particular program. The resource values tend to be
  more specific, and will be different for every dialog. Sometimes you
  might want to compare both className and resource, to make sure you
  are matching only a particular window which belongs to a specific
  program.

  Once you've pinpointed the window you want to manipulate, here are
  a few examples of things you might do with that window:
    - doIgnore: this tells xmonad to completely ignore the window. It will
      not be tiled or floated. Useful for things like launchers and
      trays.
    - doFloat: this tells xmonad to float the window rather than tiling
      it. Handy for things that pop up, take some input, and then go away,
      such as dialogs, calculators, and so on.
    - doF (W.shift "Workspace"): this tells xmonad that when this program
      is launched it should be sent to a specific workspace. Useful
      for keeping specific tasks on specific workspaces. In the example
      below I have specific workspaces for chat, development, and
      editing images.
-}

myManagementHooks :: [ManageHook]
myManagementHooks = [
    resource =? "synapse" --> doIgnore
  , resource =? "stalonetray" --> doIgnore
  , className =? "rdesktop" --> doFloat
  , className =? "Orage" --> doFloat
  , className =? "Gnome-calendar" --> doFloat
  , (className =? "Firefox") --> viewShift "6:Web"
  , (className =? "Empathy") --> doF (W.shift "7:Chat")
  , (className =? "Pidgin") --> doF (W.shift "7:Chat")
  , (className =? "Gimp-2.8") --> doF (W.shift "9:Pix")
  , (className =? "Xfce4-notifyd") --> hasBorder False
  ]
          where viewShift = doF . liftM2 (.) W.greedyView W.shift


{-
  Workspace navigation keybindings. This is probably the part of the
  configuration I have spent the most time messing with, but understand
  the least. Be very careful if messing with this section.
-}

-- We define two lists of keycodes for use in the rest of the
-- keyboard configuration. The first is the list of numpad keys,
-- in the order they occur on the keyboard (left to right and
-- top to bottom). The second is the list of number keys, in an
-- order corresponding to the numpad. We will use these to
-- make workspace navigation commands work the same whether you
-- use the numpad or the top-row number keys. And, we also
-- use them to figure out where to go when the user
-- uses the arrow keys.
numPadKeys =
  [
    xK_KP_Home, xK_KP_Up, xK_KP_Page_Up
    , xK_KP_Left, xK_KP_Begin,xK_KP_Right
    , xK_KP_End, xK_KP_Down, xK_KP_Page_Down
    , xK_KP_Insert, xK_KP_Delete, xK_KP_Enter
  ]

numKeys =
  [
    xK_7, xK_8, xK_9
    , xK_4, xK_5, xK_6
    , xK_1, xK_2, xK_3
    , xK_0, xK_minus, xK_equal
  ]

-- Here, some magic occurs that I once grokked but has since
-- fallen out of my head. Essentially what is happening is
-- that we are telling xmonad how to navigate workspaces,
-- how to send windows to different workspaces,
-- and what keys to use to change which monitor is focused.
workSpaceKeys =
  [
    ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- zip myWorkspaces numPadKeys
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask),(copy, shiftMask .|. controlMask)]
  ] ++
  [
    ((m .|. myModMask, k), windows $ f i)
       | (i, k) <- zip myWorkspaces numKeys
       , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask),(copy, shiftMask .|. controlMask)]
  ] ++
  M.toList (planeKeys myModMask (Lines 4) Circular) ++
  [
    ((m .|. myModMask, key), screenWorkspace sc
      >>= flip whenJust (windows . f))
      | (key, sc) <- zip [xK_w, xK_e, xK_r] [1,0,2]
      , (f, m) <- [(W.view, 0), (W.shift, shiftMask),(copy, shiftMask .|. controlMask)]
  ]


{-
  Here we actually stitch together all the configuration settings
  and run xmonad. We also spawn an instance of xmobar and pipe
  content into it via the logHook.
-}

main = do
  xmprocess <- spawnPipe "xmobar ~/.xmonad/xmobarrc"
  xmonad $ ewmh $ docks $ defaults {
  handleEventHook = handleEventHook def <+> fullscreenEventHook <+> docksEventHook,
  logHook            = myLogHook xmprocess
 }

myLogHook h = do
   copies <- wsContainingCopies
   let check ws | ws `elem` copies = xmobarColor myCopiedWSColor myAltBackGroundWSColor . clickable $ ws
                | otherwise = clickable ws
   dynamicLogWithPP xmobarPP {
      ppOutput = hPutStrLn h
      , ppTitle = xmobarColor myTitleColor myBackGroundWSColor . shorten myTitleLength
      , ppCurrent = xmobarColor myCurrentWSColor myBackGroundWSColor
        . wrap myCurrentWSLeft myCurrentWSRight . clickable
      , ppVisible = xmobarColor myVisibleWSColor myBackGroundWSColor
        . wrap myVisibleWSLeft myVisibleWSRight . clickable
      , ppUrgent = xmobarColor myUrgentWSColor myBackGroundWSColor
        . wrap myUrgentWSLeft myUrgentWSRight . clickable
      , ppHidden = check
    }

defaults = def {
    -- simple stuff
    terminal           = myTerminal,
    focusFollowsMouse  = myFocusFollowsMouse,
    borderWidth        = myBorderWidth,
    modMask            = myModMask,
    workspaces         = myWorkspaces,
    normalBorderColor  = myNormalBorderColor,
    focusedBorderColor = myFocusedBorderColor,

    -- key bindings
    keys               = myKeys,
    mouseBindings      = myMouseBindings,

    -- hooks, layouts
    layoutHook         = smartBorders $ myLayouts,
    manageHook         = manageDocks <+>
                          myManageHook <+>
                          manageHook def,
    startupHook        = myStartupHook
}

xmobarEscape :: String -> String
xmobarEscape = concatMap doubleLts
  where doubleLts '<' = "<"
        doubleLts x   = [x]

replaceSymbol :: Char -> String
replaceSymbol '-' = "minus"
replaceSymbol '=' = "equal"
replaceSymbol x   = x:[]

clickable :: String -> String
clickable = click . xmobarEscape
  where click l@(x:xs) = "<action=xdotool key alt+" ++ ( replaceSymbol x ) ++ ">" ++ l ++ "</action>"
