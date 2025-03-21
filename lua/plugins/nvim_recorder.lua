return {
  'chrisgrieser/nvim-recorder',
  dependencies = 'rcarriga/nvim-notify', -- optional
  opts = {
    lessNotifications = true,
    mapping = {
      startStopRecording = 'q',
      playMacro = 'Q',
      switchSlot = '<localleader>r',
      editMacro = 'cq',
      deleteAllMacros = 'dq',
      yankMacro = 'yq',
    },
  }, -- required even with default settings, since it calls `setup()`
}
