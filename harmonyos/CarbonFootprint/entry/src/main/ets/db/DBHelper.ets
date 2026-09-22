import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

const DB_NAME: string = 'carbon_footprint.db';

const DDL: string[] = [
  `CREATE TABLE IF NOT EXISTS t_behavior_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT NOT NULL,
    sub_type TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT NOT NULL,
    factor REAL NOT NULL,
    reduction_g INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    note TEXT
  )`,
  `CREATE TABLE IF NOT EXISTS t_points_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL,
    ref_id INTEGER DEFAULT 0,
    action TEXT NOT NULL,
    points INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    created_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_task (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    points INTEGER NOT NULL,
    period TEXT NOT NULL,
    check_json TEXT DEFAULT '',
    enabled INTEGER DEFAULT 1
  )`,
  `CREATE TABLE IF NOT EXISTS t_task_completion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    task_id INTEGER NOT NULL,
    completed_at INTEGER NOT NULL
  )`,
  `CREATE TABLE IF NOT EXISTS t_badge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    condition_type TEXT NOT NULL,
    condition_value INTEGER NOT NULL,
    description TEXT DEFAULT '',
    unlocked INTEGER DEFAULT 0,
    unlocked_at INTEGER DEFAULT 0
  )`,
  `CREATE INDEX IF NOT EXISTS idx_behavior_time ON t_behavior_record (created_at)`,
  `CREATE INDEX IF NOT EXISTS idx_points_time ON t_points_record (created_at)`
];

export class DBHelper {
  private static store: relationalStore.RdbStore | null = null;

  static async init(context: common.Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    DBHelper.store = await relationalStore.getRdbStore(context, config);
    for (const sql of DDL) {
      await DBHelper.store.executeSql(sql);
    }
  }

  static get(): relationalStore.RdbStore {
    if (DBHelper.store === null) {
      throw new Error('DB not initialized');
    }
    return DBHelper.store;
  }

  static beginTx(): void {
    DBHelper.get().beginTransaction();
  }

  static commitTx(): void {
    DBHelper.get().commit();
  }

  static rollbackTx(): void {
    DBHelper.get().rollBack();
  }
}
