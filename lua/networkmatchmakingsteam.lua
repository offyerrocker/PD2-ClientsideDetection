--this file is responsible for making sure that only lobbies with this mod installed are compatible

local version = 3

_G.CLIENTSIDE_DETECTION_ORIG_MM_KEY = _G.CLIENTSIDE_DETECTION_ORIG_MM_KEY or NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY

NetworkMatchMakingSTEAM._BUILD_SEARCH_INTEREST_KEY = _G.CLIENTSIDE_DETECTION_ORIG_MM_KEY ..  "_hoxi_clientside_detection_r" .. tostring(version)
