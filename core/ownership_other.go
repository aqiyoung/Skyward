//go:build !(darwin || linux) || android

package core

import "os"

func initOwnership(homeDir string) {}

func chownToAppUser(f *os.File) error { return nil }

func scheduleReclaimOwnership() {}

func reclaimDirOwnership(path string) {}
