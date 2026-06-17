figma.showUI(__html__, { width: 1000, height: 750 });

figma.ui.onmessage = async (msg) => {
  if (msg.type === 'insert-renders') {
    const selection = figma.currentPage.selection;

    // ПЕРЕВІРКА ВИБОРУ
    if (selection.length === 0) {
      figma.notify("❌ Помилка: Ви нічого не вибрали! Клацніть на 2 прямокутники.");
      return;
    }

    if (selection.length < 2) {
      figma.notify(`⚠️ Вибрано об'єктів: ${selection.length}. Потрібно мінімум 2.`);
      return;
    }

    try {
      // Отримуємо картинки (підтримуємо обидва варіанти передачі)
      let bytes1, bytes2;
      
      if (msg.img1 && msg.img2) {
        bytes1 = new Uint8Array(msg.img1);
        bytes2 = new Uint8Array(msg.img2);
      } else if (msg.images && msg.images.length >= 2) {
        bytes1 = msg.images[0];
        bytes2 = msg.images[1];
      }

      if (!bytes1 || !bytes2) {
        figma.notify("❌ Помилка: Дані зображення не отримано.");
        return;
      }

      // Вставляємо в перший об'єкт
      if ('fills' in selection[0]) {
        const image1 = figma.createImage(bytes1);
        selection[0].fills = [{ type: 'IMAGE', imageHash: image1.hash, scaleMode: 'FILL' }];
      }

      // Вставляємо в другий об'єкт
      if ('fills' in selection[1]) {
        const image2 = figma.createImage(bytes2);
        selection[1].fills = [{ type: 'IMAGE', imageHash: image2.hash, scaleMode: 'FILL' }];
      }

      figma.notify("✅ Рендери успішно вставлено!");
    } catch (err) {
      figma.notify("🚨 Помилка: " + err.message);
      console.error(err);
    }
  }
};