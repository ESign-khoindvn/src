bool gGodMode = false;


bool (*orig_Player_TakeDamage)(void* instance, void* damageTransfer);

bool my_Player_TakeDamage(void* instance, void* damageTransfer)
{
    if (!instance || !damageTransfer)
        return orig_Player_TakeDamage(instance, damageTransfer);

    if (gGodMode)
    {
        // ép damage = 0
        *(float*)((uintptr_t)damageTransfer + 0x14) = 0.0f;
        // nếu 0x10 không ăn thì đổi 0x14 / 0x18 như bạn test trước
    }

    // vẫn cho game xử lý bình thường
    return orig_Player_TakeDamage(instance, damageTransfer);
}
