package core

import (
	"fmt"
	"os"

	"github.com/metacubex/mihomo/component/age"
	"go.yaml.in/yaml/v3"
)

// Helpers used by the chain implementation. In ReClash these wrap a desktop
// privileged-path policy; here the core already runs with the host's own file
// permissions, so plain file access is enough.

func readCoreFile(path string) ([]byte, error) {
	return os.ReadFile(path)
}

func makeCoreDirectory(path string, mode os.FileMode) error {
	return os.MkdirAll(path, mode)
}

func readConfigMapping(path string) (*yaml.Node, error) {
	buf, err := readCoreFile(path)
	if err != nil {
		return nil, err
	}
	if buf, err = age.DecryptBytes(buf); err != nil {
		return nil, fmt.Errorf("decrypt config error: %w", err)
	}
	var document yaml.Node
	if err := yaml.Unmarshal(buf, &document); err != nil {
		return nil, err
	}
	return documentMapping(&document)
}
