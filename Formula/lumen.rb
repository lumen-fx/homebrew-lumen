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
# lumen-server, the production server for server-rendered sites, needs nothing
# beside it; it gets the same exec script so both commands are installed the
# same way. `lumenc web --serve` finds it beside lumenc in libexec.
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
  version "0.0.8"
  license "MPL-2.0"

  on_macos do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.8/lumen-macos-aarch64.tar.gz"
      sha256 "0a6299914b1895d184dc4db735e06f0eb8b16483cd0b3a8230be0964e819af09"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.8/lumen-macos-x86_64.tar.gz"
      sha256 "a0334914fb132932569b65186103468361c4203e009db6826e0f73f3fa05d1af"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.8/lumen-linux-aarch64.tar.gz"
      sha256 "e71fbd8bf278233316fdace347223afdd7a1bad8dbfdc8f26d0e18ae9a0fe4c4"
    end

    on_intel do
      url "https://github.com/lumen-fx/lumen/releases/download/v0.0.8/lumen-linux-x86_64.tar.gz"
      sha256 "e22fa27c4f05169b0959d15cf864970af3ee94a1c17b1f11f9a79cfd9db38f51"
    end
  end

  livecheck do
    url :stable
    strategy :github_latest
  end

  def install
    libexec.install Dir["bin/*"]
    bin.write_exec_script libexec/"lumenc"
    bin.write_exec_script libexec/"lumen-server"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/lumenc --version")

    system bin/"lumenc", "new", "smoke"
    assert_predicate testpath/"smoke/main.lmn", :exist?
    assert_match "ok", shell_output("#{bin}/lumenc check smoke")
  end
end
