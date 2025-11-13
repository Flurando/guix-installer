;;; Copyright © 2019 Alex Griffin <a@ajgrf.com>
;;; Copyright © 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;;; Copyright © 2019,2024 David Wilson <david@daviwil.com>
;;; Copyright © 2022 Jonathan Brielmaier <jonathan.brielmaier@web.de>
;;; Copyright © 2024 Hilton Chain <hako@ultrarare.space>
;;;
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;;
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Generate a bootable image (e.g. for USB sticks, etc.) with:
;; $ guix system image -t iso9660 installer.scm

(define-module (nongnu system install)
  #:use-module (srfi srfi-1)
  #:use-module (guix)
  #:use-module (guix channels)
  #:use-module (guix inferior)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mtools)
  #:use-module (gnu packages package-management)
  #:use-module (gnu packages wget)
  #:use-module (gnu services)
  #:use-module (gnu services base)
  #:use-module (gnu system)
  #:use-module (gnu system install)
  #:use-module (nongnu packages linux)
  #:export (installation-os-nonfree))

;; https://substitutes.nonguix.org/signing-key.pub
(define %signing-key
  (plain-file "nonguix.pub" "\
(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

(define %channels
  (cons* (channel
          (name 'nonguix)
          (url "https://gitlab.com/nonguix/nonguix")
          ;; Enable signature verification:
          (introduction
           (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
             "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
         %default-channels))

(define installation-os-nonfree
  (operating-system
   (inherit installation-os)
   ;; we must pin kernel to an older version, because GitHub Runner does not have the resource to compile the newest linux kernel itself
   (kernel
    (let*
        ((channels
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
         (inferior
          (inferior-for-channels channels)))
      (first (lookup-inferior-packages inferior "linux" "6.17.7"))))
   (firmware (list linux-firmware))

   ;; Add the 'net.ifnames' argument to prevent network interfaces
   ;; from having really long names.  This can cause an issue with
   ;; wpa_supplicant when you try to connect to a wifi network.
   (kernel-arguments '("quiet" "modprobe.blacklist=radeon" "net.ifnames=0"))

   (services
    (cons*
     ;; Include the channel file so that it can be used during installation
     (simple-service 'channel-file etc-service-type
                     (list `("channels.scm" ,(local-file "channels.scm"))))

     (modify-services (operating-system-user-services installation-os)
		      (guix-service-type
		       config => (guix-configuration
				  (inherit config)
				  (guix (guix-for-channels %channels))
				  (authorized-keys
				   (cons* %signing-key
					  %default-authorized-guix-keys))
				  (substitute-urls
				   `(,@%default-substitute-urls
				     "https://substitutes.nonguix.org"))
				  (channels %channels))))))

   ;; Add some extra packages useful for the installation process
   (packages
    (append (list git curl wget emacs-no-x)
            (operating-system-packages installation-os)))))

installation-os-nonfree
