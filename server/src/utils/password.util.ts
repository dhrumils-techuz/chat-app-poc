import bcrypt from 'bcryptjs';
import { PasswordMsg } from '../constants/messages';

const SALT_ROUNDS = 12;

export async function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, SALT_ROUNDS);
}

export async function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}$/;

export function validatePasswordComplexity(password: string): { valid: boolean; message: string } {
  if (password.length < 8) {
    return { valid: false, message: PasswordMsg.MIN_LENGTH };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: PasswordMsg.LOWERCASE_REQUIRED };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: PasswordMsg.UPPERCASE_REQUIRED };
  }
  if (!/\d/.test(password)) {
    return { valid: false, message: PasswordMsg.NUMBER_REQUIRED };
  }
  if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
    return { valid: false, message: PasswordMsg.SPECIAL_CHAR_REQUIRED };
  }
  return { valid: true, message: PasswordMsg.MEETS_REQUIREMENTS };
}
