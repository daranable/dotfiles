
import XMonad
import XMonad.Actions.NoBorders
import XMonad.Hooks.ManageHelpers
import XMonad.Layout.NoBorders

import System.Exit
import System.Posix.Process (executeFile, createSession)

import qualified XMonad.StackSet as W

import qualified Data.Map as M

-- double-fork and execvp a command
exec :: MonadIO m => [String] -> m ()
exec [] = error "exec requires at least a command"
exec (cmd:args) =
    let usePath = True
        environ = Nothing
        command = executeFile cmd usePath args environ
    in  xfork command >> return ()

myKeys :: XConfig Layout -> M.Map (KeyMask, KeySym) (X ())
myKeys conf@(XConfig {XMonad.modMask = modMask}) = M.fromList $
    [ ((modMask .|. shiftMask,  xK_Return   ), exec [terminal conf])
    , ((modMask              ,  xK_Return   ), exec ["gmrun"])

    , ((modMask .|. shiftMask,  xK_c        ), kill)

    , ((modMask,                xK_j        ), windows W.focusDown)
    , ((modMask,                xK_k        ), windows W.focusUp)
    , ((modMask,                xK_m        ), windows W.focusMaster)

    , ((modMask .|. shiftMask,  xK_j        ), windows W.swapDown)
    , ((modMask .|. shiftMask,  xK_k        ), windows W.swapUp)
    , ((modMask .|. shiftMask,  xK_m        ), windows W.swapMaster)

    , ((modMask,                xK_h        ), sendMessage Shrink)
    , ((modMask,                xK_l        ), sendMessage Expand)

    , ((modMask,                xK_comma    ), sendMessage (IncMasterN 1))
    , ((modMask,                xK_period   ), sendMessage (IncMasterN (-1)))

    , ((modMask,                xK_t        ), withFocused $ windows . W.sink)
--    , ((modMask .|. shiftMask,  xK_t        ), withFocused $ windows . W.float)

    , ((modMask,                xK_g        ), withFocused $ toggleBorder)

    , ((modMask .|. shiftMask,  xK_q        ), io exitSuccess)
    , ((modMask,                xK_q        ), spawn (
        "if type xmonad; then xmonad --recompile && xmonad --restart;"
        ++ " else xmessage xmonad not in \\$PATH: \"$PATH\"; fi"))
    ]
    ++
    [ ((m .|. modMask, k), windows $ f i)
        | (i, k) <- zip (XMonad.workspaces conf) ([xK_1 .. xK_9]++[xK_0,xK_minus,xK_plus])
        , (f, m) <- [(W.greedyView, 0), (W.shift, shiftMask)] ]
    ++
    [((m .|. modMask, key), screenWorkspace sc >>= flip whenJust (windows . f))
        | (key, sc) <- zip [xK_w, xK_e, xK_r] [0..]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]]

main = xmonad $ defaultConfig
    { terminal = "xterm"
    , workspaces = map show [1 .. 12 :: Int]
    , keys = myKeys
    , layoutHook = smartBorders $ layoutHook defaultConfig
    }
