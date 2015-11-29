#lang racket

(define (opcode n) (arithmetic-shift n 32))
(define (low-bits n m)
  (bitwise-and n (- (arithmetic-shift 1 m) 1)))
(define (op-out)
  (opcode #x1))
(define (op-call addr)
  (bitwise-ior (opcode #x2) addr))
(define (op-ret)
  (opcode #x3))
(define (op-imm32 val)
  (bitwise-ior (opcode #x4) val))
(define (op-store)
  (opcode #x5))
(define (op-load)
  (opcode #x6))
(define (op-if addr)
  (bitwise-ior
   (opcode #x7)
   (low-bits (abs addr) 10)
   (arithmetic-shift (if (> addr 0) 1 0) 10)))
(define (op-eq)
  (opcode #x8))
(define (op-add)
  (opcode #x9))
(define (op-dup)
  (opcode #xA))

(define blinky1
  (vector-immutable
   (op-imm32 1)
   (op-out)
   (op-imm32 0)
   (op-out)
   (op-imm32 1)
   (op-if -2)))

(define add-test
  (vector-immutable
   (op-imm32 1)
   (op-imm32 1)
   (op-add)
   (op-imm32 2)
   (op-eq)
   (op-out)
   (op-imm32 1)
   (op-if -2)))

(define bootrom
  (vector-immutable
   (op-imm32 20)
   (op-dup)
   (op-imm32 1024)
   (op-eq)
   (op-if 7)
   (op-imm32 1)
   (op-add)
   (op-dup)
   (op-store)
   (op-imm32 1)
   (op-if -9)
   (op-imm32 1)
   (op-out)
   (op-imm32 1)
   (op-if -1)))

(define (write-initial-memory rom path)
  (with-output-to-file path
    (lambda ()
      (for ((i (in-range 1024)))
        (printf "~X~%"
                (if (< i (vector-length rom))
                    (vector-ref rom i)
                    0))))
    #:exists 'replace))

(write-initial-memory add-test "ram.bin")
