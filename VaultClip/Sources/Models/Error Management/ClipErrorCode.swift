//
// ClipErrorCode — stable NSError codes for VaultClip history and UI errors.
//
// Copyright (C) 2026 Aleksey Karakuts <aleksey@karakuts.com>
//
// SPDX-License-Identifier: GPL-3.0-or-later
//
import Foundation

enum ClipErrorCode: Int {

  // MARK: - History persistence (1xxx)

  case unknown = 0
  case historyOrderWriteFailed = 1001
  case historyOrderDecryptFailed = 1002
  case historyItemDataLoadFailed = 1003
  case historyDirectoryListFailed = 1004
  case historyItemLoadFailed = 1005
  case historyItemSaveFailed = 1006
  case historyItemDeleteFailed = 1007
  case historyClearFailed = 1008
  case historyMetadataWriteFailed = 1009
  case historyOrderLoadFailed = 1010

  // MARK: - UI / preview (2xxx)

  case invalidPanelPosition = 2001
  case previewPanelNil = 2002
  case thumbnailCreationFailed = 2003

  // MARK: - Cache (3xxx)

  case cacheDataNotFound = 3001
}
