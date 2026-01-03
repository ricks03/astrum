/**
 * WailsFS - BrowserFS backend using Wails Go bindings
 *
 * This replaces IndexedDB with native filesystem access through Go,
 * enabling real-time file sync with the session's game directory.
 *
 * Part of the Astrum project integration.
 */
(function(global) {
    'use strict';

    // Get BrowserFS reference
    var BrowserFS = global.BrowserFS;
    if (!BrowserFS) {
        console.warn('WailsFS: BrowserFS not found, skipping registration');
        return;
    }

    var Buffer = BrowserFS.BFSRequire('buffer').Buffer;
    var ApiError = BrowserFS.ApiError;
    var ErrorCode = BrowserFS.ErrorCode;

    // BrowserFS Stats constructor - we need to create stats objects
    // compatible with BrowserFS's expectations
    function makeStats(result) {
        var mode = result.isDir ? 0o40755 : 0o100644;
        return {
            dev: 0,
            ino: 0,
            mode: mode,
            nlink: 1,
            uid: 0,
            gid: 0,
            rdev: 0,
            size: result.size,
            blksize: 4096,
            blocks: Math.ceil(result.size / 512),
            atime: new Date(result.atime),
            mtime: new Date(result.mtime),
            ctime: new Date(result.ctime),
            birthtime: new Date(result.ctime),
            // BrowserFS-specific methods
            isFile: function() { return !result.isDir; },
            isDirectory: function() { return result.isDir; },
            isBlockDevice: function() { return false; },
            isCharacterDevice: function() { return false; },
            isSymbolicLink: function() { return false; },
            isFIFO: function() { return false; },
            isSocket: function() { return false; }
        };
    }

    /**
     * A BrowserFS backend that uses Wails Go bindings for file operations.
     * Designed to work with AsyncMirror for sync operations.
     */
    function WailsFS(options, cb) {
        this._sessionKey = options.sessionKey || null;
        this._ready = false;

        var self = this;

        // Verify Wails bindings are available
        if (!WailsFS.isAvailable()) {
            if (cb) cb(new ApiError(ErrorCode.EINVAL, 'Wails bindings not available'));
            return;
        }

        if (!this._sessionKey) {
            if (cb) cb(new ApiError(ErrorCode.EINVAL, 'Session key is required'));
            return;
        }

        // Mark as ready
        this._ready = true;
        if (cb) cb(null, this);
    }

    /**
     * Check if Wails bindings are available
     */
    WailsFS.isAvailable = function() {
        return typeof window !== 'undefined' &&
               typeof window.go !== 'undefined' &&
               typeof window.go.main !== 'undefined' &&
               typeof window.go.main.App !== 'undefined' &&
               typeof window.go.main.App.FSReadFile === 'function';
    };

    WailsFS.prototype.getName = function() {
        return 'WailsFS';
    };

    WailsFS.prototype.isReadOnly = function() {
        return false;
    };

    WailsFS.prototype.supportsLinks = function() {
        return false;
    };

    WailsFS.prototype.supportsProps = function() {
        return false;
    };

    WailsFS.prototype.supportsSynch = function() {
        return false; // Async only - use with AsyncMirror
    };

    /**
     * Empty callback for operations that don't need special handling
     */
    WailsFS.prototype.empty = function(cb) {
        cb(null);
    };

    /**
     * Async stat
     */
    WailsFS.prototype.stat = function(path, isLstat, cb) {
        var self = this;
        window.go.main.App.FSStat(this._sessionKey, path)
            .then(function(result) {
                cb(null, makeStats(result));
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(path));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async readdir
     */
    WailsFS.prototype.readdir = function(path, cb) {
        window.go.main.App.FSReaddir(this._sessionKey, path)
            .then(function(entries) {
                cb(null, entries || []);
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(path));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async readFile
     */
    WailsFS.prototype.readFile = function(fname, encoding, flag, cb) {
        window.go.main.App.FSReadFile(this._sessionKey, fname)
            .then(function(data) {
                // Go returns byte array, convert to Buffer
                var buf;
                if (data instanceof Uint8Array) {
                    buf = Buffer.from(data);
                } else if (Array.isArray(data)) {
                    buf = Buffer.from(data);
                } else {
                    buf = Buffer.from(data);
                }

                if (encoding) {
                    cb(null, buf.toString(encoding));
                } else {
                    cb(null, buf);
                }
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(fname));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async writeFile
     */
    WailsFS.prototype.writeFile = function(fname, data, encoding, flag, mode, cb) {
        var bytes;
        if (Buffer.isBuffer(data)) {
            bytes = Array.from(data);
        } else if (data instanceof Uint8Array) {
            bytes = Array.from(data);
        } else if (typeof data === 'string') {
            bytes = Array.from(Buffer.from(data, encoding || 'utf8'));
        } else if (Array.isArray(data)) {
            bytes = data;
        } else {
            bytes = Array.from(data);
        }

        window.go.main.App.FSWriteFile(this._sessionKey, fname, bytes, mode || 0o644)
            .then(function() {
                cb(null);
            })
            .catch(function(err) {
                cb(new ApiError(ErrorCode.EIO, err.message || String(err)));
            });
    };

    /**
     * Async mkdir
     */
    WailsFS.prototype.mkdir = function(path, mode, cb) {
        window.go.main.App.FSMkdir(this._sessionKey, path, mode || 0o755)
            .then(function() {
                cb(null);
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('exists')) {
                    cb(ApiError.EEXIST(path));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async unlink (delete file)
     */
    WailsFS.prototype.unlink = function(path, cb) {
        window.go.main.App.FSUnlink(this._sessionKey, path)
            .then(function() {
                cb(null);
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(path));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async rmdir
     */
    WailsFS.prototype.rmdir = function(path, cb) {
        window.go.main.App.FSRmdir(this._sessionKey, path)
            .then(function() {
                cb(null);
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(path));
                } else if (errMsg.includes('not empty')) {
                    cb(ApiError.ENOTEMPTY(path));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async rename
     */
    WailsFS.prototype.rename = function(oldPath, newPath, cb) {
        window.go.main.App.FSRename(this._sessionKey, oldPath, newPath)
            .then(function() {
                cb(null);
            })
            .catch(function(err) {
                var errMsg = err.message || String(err);
                if (errMsg.includes('no such file') || errMsg.includes('does not exist')) {
                    cb(ApiError.ENOENT(oldPath));
                } else {
                    cb(new ApiError(ErrorCode.EIO, errMsg));
                }
            });
    };

    /**
     * Async exists check
     */
    WailsFS.prototype.exists = function(path, cb) {
        window.go.main.App.FSExists(this._sessionKey, path)
            .then(function(exists) {
                cb(exists);
            })
            .catch(function() {
                cb(false);
            });
    };

    /**
     * Create an empty file (used for initialization)
     */
    WailsFS.prototype.createFile = function(path, flag, mode, cb) {
        this.writeFile(path, Buffer.alloc(0), null, flag, mode, cb);
    };

    /**
     * Open file - returns a file descriptor (not fully implemented, defers to read/write)
     */
    WailsFS.prototype.open = function(path, flags, mode, cb) {
        // WailsFS doesn't use file descriptors - operations are path-based
        // Return a dummy fd for compatibility
        var self = this;
        this.stat(path, false, function(err, stats) {
            if (err && flags.pathNotExistsAction() === 3) {
                // Create if doesn't exist and flag says so
                self.createFile(path, flags, mode, function(createErr) {
                    if (createErr) {
                        cb(createErr);
                    } else {
                        cb(null, { path: path, flags: flags, mode: mode });
                    }
                });
            } else if (err) {
                cb(err);
            } else {
                cb(null, { path: path, flags: flags, mode: mode, stats: stats });
            }
        });
    };

    /**
     * Close file descriptor - no-op for WailsFS
     */
    WailsFS.prototype.close = function(fd, cb) {
        cb(null);
    };

    /**
     * Read from file descriptor
     */
    WailsFS.prototype.read = function(fd, buffer, offset, length, position, cb) {
        var self = this;
        this.readFile(fd.path, null, fd.flags, function(err, data) {
            if (err) {
                cb(err);
                return;
            }
            var start = position || 0;
            var end = Math.min(start + length, data.length);
            var bytesRead = end - start;
            data.copy(buffer, offset, start, end);
            cb(null, bytesRead, buffer);
        });
    };

    /**
     * Write to file descriptor
     */
    WailsFS.prototype.write = function(fd, buffer, offset, length, position, cb) {
        var self = this;
        var dataToWrite = buffer.slice(offset, offset + length);

        // If position is specified and not at start, we need to read-modify-write
        if (position && position > 0) {
            this.readFile(fd.path, null, fd.flags, function(err, existingData) {
                var newData;
                if (err || !existingData) {
                    // File doesn't exist or error, create new
                    newData = Buffer.alloc(position + length);
                    dataToWrite.copy(newData, position);
                } else {
                    // Merge with existing data
                    var newLength = Math.max(existingData.length, position + length);
                    newData = Buffer.alloc(newLength);
                    existingData.copy(newData, 0);
                    dataToWrite.copy(newData, position);
                }
                self.writeFile(fd.path, newData, null, fd.flags, fd.mode, function(writeErr) {
                    if (writeErr) {
                        cb(writeErr);
                    } else {
                        cb(null, length, buffer);
                    }
                });
            });
        } else {
            // Simple write
            this.writeFile(fd.path, dataToWrite, null, fd.flags, fd.mode, function(writeErr) {
                if (writeErr) {
                    cb(writeErr);
                } else {
                    cb(null, length, buffer);
                }
            });
        }
    };

    /**
     * Truncate file
     */
    WailsFS.prototype.truncate = function(path, len, cb) {
        var self = this;
        this.readFile(path, null, null, function(err, data) {
            if (err) {
                // If file doesn't exist, create empty file
                self.writeFile(path, Buffer.alloc(len), null, null, 0o644, cb);
                return;
            }
            var newData;
            if (len < data.length) {
                newData = data.slice(0, len);
            } else {
                newData = Buffer.alloc(len);
                data.copy(newData, 0);
            }
            self.writeFile(path, newData, null, null, 0o644, cb);
        });
    };

    /**
     * Sync file - no-op for WailsFS (writes are immediate)
     */
    WailsFS.prototype.fsync = function(fd, cb) {
        cb(null);
    };

    /**
     * fstat - stat via file descriptor
     */
    WailsFS.prototype.fstat = function(fd, cb) {
        this.stat(fd.path, false, cb);
    };

    // Register with BrowserFS
    BrowserFS.FileSystem.WailsFS = WailsFS;

    // Also expose globally for debugging
    global.WailsFS = WailsFS;

    console.log('WailsFS: Backend registered with BrowserFS');

})(typeof window !== 'undefined' ? window : global);
