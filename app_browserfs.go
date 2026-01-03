package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/neper-stars/astrum/lib/logger"
)

// =============================================================================
// BROWSERFS BINDINGS - File system operations for embedded Stars! browser
// =============================================================================

// FSStatResult represents file metadata for BrowserFS
type FSStatResult struct {
	Size    int64 `json:"size"`
	Mode    int   `json:"mode"`
	IsDir   bool  `json:"isDir"`
	ModTime int64 `json:"modTime"` // Unix timestamp in milliseconds
	Atime   int64 `json:"atime"`
	Mtime   int64 `json:"mtime"`
	Ctime   int64 `json:"ctime"`
}

// FSFileEntry represents a file for bulk listing
type FSFileEntry struct {
	Path  string `json:"path"`
	IsDir bool   `json:"isDir"`
	Size  int64  `json:"size"`
	Mode  int    `json:"mode"`
}

// getGameDirFromSessionKey parses "serverURL|sessionID" and returns the game directory
func (a *App) getGameDirFromSessionKey(sessionKey string) (string, error) {
	parts := strings.SplitN(sessionKey, "|", 2)
	if len(parts) != 2 {
		return "", fmt.Errorf("invalid session key format: expected 'serverURL|sessionID'")
	}
	serverURL, sessionID := parts[0], parts[1]

	if serverURL == "" || sessionID == "" {
		return "", fmt.Errorf("invalid session key: serverURL and sessionID cannot be empty")
	}

	// Get server by URL to find the server name
	server, err := a.config.GetServer(serverURL)
	if err != nil {
		return "", fmt.Errorf("failed to get server: %w", err)
	}

	serverName := serverURL // fallback to URL if server not found
	if server != nil {
		serverName = server.Name
	}

	// Get the game directory
	gameDir, err := a.config.GetSessionGameDir(serverName, sessionID)
	if err != nil {
		return "", fmt.Errorf("failed to get game directory: %w", err)
	}

	return gameDir, nil
}

// sanitizePath prevents directory traversal attacks
func (a *App) sanitizePath(basePath, relativePath string) (string, error) {
	// Normalize the relative path
	cleaned := filepath.Clean(relativePath)

	// Remove leading slashes for proper joining
	cleaned = strings.TrimPrefix(cleaned, "/")
	cleaned = strings.TrimPrefix(cleaned, "\\")

	// Check for directory traversal attempts
	if strings.HasPrefix(cleaned, "..") || strings.Contains(cleaned, "/../") || strings.Contains(cleaned, "\\..\\") {
		return "", fmt.Errorf("invalid path: directory traversal not allowed")
	}

	// Also reject absolute paths
	if filepath.IsAbs(cleaned) {
		return "", fmt.Errorf("invalid path: absolute paths not allowed")
	}

	fullPath := filepath.Join(basePath, cleaned)

	// Verify the result is still within basePath
	absBase, err := filepath.Abs(basePath)
	if err != nil {
		return "", fmt.Errorf("failed to resolve base path: %w", err)
	}
	absPath, err := filepath.Abs(fullPath)
	if err != nil {
		return "", fmt.Errorf("failed to resolve path: %w", err)
	}

	if !strings.HasPrefix(absPath, absBase) {
		return "", fmt.Errorf("path escapes base directory")
	}

	return fullPath, nil
}

// FSReadFile reads a file from the session's game directory
func (a *App) FSReadFile(sessionKey, path string) ([]byte, error) {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("path", path).
		Msg("FSReadFile")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return nil, err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return nil, err
	}

	data, err := os.ReadFile(fullPath)
	if err != nil {
		return nil, err
	}

	logger.App.Debug().
		Str("path", path).
		Int("size", len(data)).
		Msg("FSReadFile completed")

	return data, nil
}

// FSWriteFile writes a file to the session's game directory
func (a *App) FSWriteFile(sessionKey, path string, data []byte, mode int) error {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("path", path).
		Int("size", len(data)).
		Int("mode", mode).
		Msg("FSWriteFile")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return err
	}

	// Ensure parent directory exists
	dir := filepath.Dir(fullPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return fmt.Errorf("failed to create parent directory: %w", err)
	}

	// Use default mode if not specified
	fileMode := os.FileMode(mode)
	if mode == 0 {
		fileMode = 0644
	}

	if err := os.WriteFile(fullPath, data, fileMode); err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	logger.App.Debug().
		Str("path", path).
		Msg("FSWriteFile completed")

	return nil
}

// FSStat returns file/directory stats
func (a *App) FSStat(sessionKey, path string) (*FSStatResult, error) {
	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return nil, err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return nil, err
	}

	info, err := os.Stat(fullPath)
	if err != nil {
		return nil, err
	}

	modTime := info.ModTime().UnixMilli()
	return &FSStatResult{
		Size:    info.Size(),
		Mode:    int(info.Mode()),
		IsDir:   info.IsDir(),
		ModTime: modTime,
		Atime:   modTime, // Go doesn't easily expose atime, use mtime
		Mtime:   modTime,
		Ctime:   modTime,
	}, nil
}

// FSReaddir lists directory contents
func (a *App) FSReaddir(sessionKey, path string) ([]string, error) {
	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return nil, err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return nil, err
	}

	entries, err := os.ReadDir(fullPath)
	if err != nil {
		return nil, err
	}

	names := make([]string, len(entries))
	for i, entry := range entries {
		names[i] = entry.Name()
	}
	return names, nil
}

// FSMkdir creates a directory
func (a *App) FSMkdir(sessionKey, path string, mode int) error {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("path", path).
		Msg("FSMkdir")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return err
	}

	fileMode := os.FileMode(mode)
	if mode == 0 {
		fileMode = 0755
	}

	return os.Mkdir(fullPath, fileMode)
}

// FSUnlink deletes a file
func (a *App) FSUnlink(sessionKey, path string) error {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("path", path).
		Msg("FSUnlink")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return err
	}

	// Verify it's a file, not a directory
	info, err := os.Stat(fullPath)
	if err != nil {
		return err
	}
	if info.IsDir() {
		return fmt.Errorf("path is a directory, use FSRmdir instead")
	}

	return os.Remove(fullPath)
}

// FSRmdir removes a directory
func (a *App) FSRmdir(sessionKey, path string) error {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("path", path).
		Msg("FSRmdir")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return err
	}

	// Verify it's a directory
	info, err := os.Stat(fullPath)
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return fmt.Errorf("path is not a directory")
	}

	return os.Remove(fullPath)
}

// FSExists checks if a path exists
func (a *App) FSExists(sessionKey, path string) (bool, error) {
	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return false, err
	}

	fullPath, err := a.sanitizePath(gameDir, path)
	if err != nil {
		return false, err
	}

	_, err = os.Stat(fullPath)
	if os.IsNotExist(err) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return true, nil
}

// FSRename renames/moves a file
func (a *App) FSRename(sessionKey, oldPath, newPath string) error {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Str("oldPath", oldPath).
		Str("newPath", newPath).
		Msg("FSRename")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return err
	}

	oldFull, err := a.sanitizePath(gameDir, oldPath)
	if err != nil {
		return err
	}

	newFull, err := a.sanitizePath(gameDir, newPath)
	if err != nil {
		return err
	}

	return os.Rename(oldFull, newFull)
}

// FSListAll returns all files in the game directory (for initialization/sync)
func (a *App) FSListAll(sessionKey string) ([]FSFileEntry, error) {
	logger.App.Debug().
		Str("sessionKey", sessionKey[:min(20, len(sessionKey))]+"...").
		Msg("FSListAll")

	gameDir, err := a.getGameDirFromSessionKey(sessionKey)
	if err != nil {
		return nil, err
	}

	// Ensure directory exists
	if err := os.MkdirAll(gameDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create game directory: %w", err)
	}

	var entries []FSFileEntry
	err = filepath.Walk(gameDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip errors, continue walking
		}

		relPath, _ := filepath.Rel(gameDir, path)
		if relPath == "." {
			return nil // Skip root
		}

		entries = append(entries, FSFileEntry{
			Path:  "/" + filepath.ToSlash(relPath),
			IsDir: info.IsDir(),
			Size:  info.Size(),
			Mode:  int(info.Mode()),
		})
		return nil
	})

	logger.App.Debug().
		Int("count", len(entries)).
		Msg("FSListAll completed")

	return entries, err
}
