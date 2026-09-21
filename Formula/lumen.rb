# Homebrew formula for the Lumen toolchain. It lives in the tap
# lumen-fx/homebrew-lumen as Formula/lumen.rb, which is what
# `brew install lumen-fx/lumen/lumen` reads, and
# .github/workflows/publish-packages.yml pushes this file there on every
# release.
#
# The formula installs the release archive rather than building from source:
# every platform Lumen publishes for already has an archive on the release, and
# building the workspace needs a Rust toolchain the formula would otherwise
# have to pull in.
#
# The three files stay in one directory because lumenc dlopens the runtime
# library from beside its own executable, and `lumenc package` looks for the
# launcher stub in that same directory (public/lumenc/src/link/loader.rs,
# public/lumenc/src/package/package.rs). libexec holds all three and bin gets a
# script that execs the real lumenc, so the running executable is the one in
# libexec no matter how it was invoked. A plain symlink in bin would not do:
# macOS reports the path used to launch, not the resolved one, and the library
# would go missing.
#
# Nothing here installs a receipt under share/lumen. That file is what marks a
# copy as installed and turns the built-in update check on
# (public/lumenc/src/package/update_check.rs); without it lumenc never checks for a
# newer release, which is what you want when brew owns the version.
#
# The Linux archives link the distribution's GTK 3, ALSA, and Wayland or X11
# libraries. They are not declared as formula dependencies because the
# binaries look for the system copies, not brewed ones.

class Lumen < Formula
  desc "Toolchain for Lumen, a markup-first UI framework for native desktop apps"
  homepage "https://lumenfx.dev"
  version "0.0.7"
  license "MPL-2.0"

  on_macos do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.7/lumen-macos-aarch64.tar.gz"
      sha256 "542dceae61348d46e20e037c2bd4eb55c2ab7ebbc09760c0a15e89562e0aabc6"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.7/lumen-macos-x86_64.tar.gz"
      sha256 "92eb9337ec20b31f9e37b45d8a14c577d6b3730ce5731886371e63a4e232675b"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.7/lumen-linux-aarch64.tar.gz"
      sha256 "4a6667370f0ceb66e41193b002b6337f20eba2438243e4d7b1cac3cc66a7f2f1"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.7/lumen-linux-x86_64.tar.gz"
      sha256 "c1ef489491bf2955eca5d3b09d66d14c9ab2c1e7b403a2dee7e67ad49768afae"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    libexec.install Dir["bin/*"]
    bin.write_exec_script libexec/"lumenc"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lumenc --version")

    system bin/"lumenc", "new", "smoke"
    assert_predicate testpath/"smoke/main.lmn", :exist?
    assert_match "ok", shell_output("#{bin}/lumenc check smoke")
  end
end
