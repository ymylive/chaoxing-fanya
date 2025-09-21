# -*- coding:utf-8 -*-
import base64
import pyaes
from Crypto.Cipher import DES
from Crypto.Util.Padding import pad
from api.config import GlobalConst as gc


def pkcs7_unpadding(string):
    return string[0 : -ord(string[-1])]


def pkcs7_padding(s, block_size=16):
    bs = block_size
    return s + (bs - len(s) % bs) * chr(bs - len(s) % bs).encode()


def split_to_data_blocks(byte_str, block_size=16):
    length = len(byte_str)
    j, y = divmod(length, block_size)
    blocks = []
    shenyu = j * block_size
    for i in range(j):
        start = i * block_size
        end = (i + 1) * block_size
        blocks.append(byte_str[start:end])
    stext = byte_str[shenyu:]
    if stext:
        blocks.append(stext)
    return blocks


class AESCipher:
    def __init__(self):
        self.key = str(gc.AESKey).encode("utf8")
        self.iv = str(gc.AESKey).encode("utf8")

    def encrypt(self, plaintext: str):
        ciphertext = b""
        cbc = pyaes.AESModeOfOperationCBC(self.key, self.iv)
        plaintext = plaintext.encode("utf-8")
        blocks = split_to_data_blocks(pkcs7_padding(plaintext))
        for b in blocks:
            ciphertext = ciphertext + cbc.encrypt(b)
        base64_text = base64.b64encode(ciphertext).decode("utf8")
        return base64_text

    # def decrypt(self, ciphertext: str):
    #     cbc = pyaes.AESModeOfOperationCBC(self.key, self.iv)
    #     ciphertext.encode('utf8')
    #     ciphertext = base64.b64decode(ciphertext)
    #     ptext = b""
    #     for b in split_to_data_blocks(ciphertext):
    #         ptext = ptext + cbc.decrypt(b)
    #     return pkcs7_unpadding(ptext.decode())


class DESCipher:
    """DES加密类，用于超星学习通新版登录API"""
    def __init__(self):
        # 根据搜索结果，使用指定的IV作为密钥的前8字节
        self.key = b"u2oh6Vu^"  # DES密钥为8字节
        
    def encrypt(self, plaintext: str):
        """使用DES ECB模式加密密码"""
        try:
            # 将明文转换为字节
            plaintext_bytes = plaintext.encode('utf-8')
            
            # 创建DES加密器，使用ECB模式
            cipher = DES.new(self.key, DES.MODE_ECB)
            
            # 填充明文到8字节的倍数
            padded_data = pad(plaintext_bytes, DES.block_size)
            
            # 加密
            encrypted = cipher.encrypt(padded_data)
            
            # Base64编码
            return base64.b64encode(encrypted).decode('utf-8')
        except Exception as e:
            # 如果DES加密失败，回退到原来的AES方式
            aes_cipher = AESCipher()
            return aes_cipher.encrypt(plaintext)
