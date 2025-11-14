;; Reference :: https://gitlab.com/nonguix/nonguix
(define-module (base-channels)
  #:use-module (guix)
  #:use-module (guix channels)
  #:export (%channels))

(define %channels
  (list (channel
	 (name 'nonguix)
	 (url "https://gitlab.com/nonguix/nonguix")
	 (commit "ba6ce23e785d1ccd9194202d8f27f6db4b649170")
	 (introduction
	  (make-channel-introduction
	   "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
	   (openpgp-fingerprint
	    "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
	(channel
	 (name 'guix)
	 (url "https://git.savannah.gnu.org/git/guix.git")
	 (commit "a1cdcd2cabb59e731349b13777a044b48ef4f844")
	 (introduction
	  (make-channel-introduction
	   "9edb3f66fd807b096b48283debdcddccfea34bad"
	   (openpgp-fingerprint
	    "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA"))))))

%channels
